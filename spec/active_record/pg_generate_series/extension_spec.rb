# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecord::PgGenerateSeries::Extension do
  # rollback after each examples
  around do |example|
    ActiveRecord::Base.transaction do
      example.call
      raise ActiveRecord::Rollback
    end
  end

  describe '#insert_using_generate_series' do
    subject { User.insert_using_generate_series(first, last, options, &block) }

    let(:first) { 1 }
    let(:last) { 3 }
    let(:options) { {} }
    let(:block) do
      proc do |sql|
        sql.name = 'name'
        sql.age = 16
        sql.birth_date = Date.new(2000, 1, 1)
        sql.disabled = true
      end
    end

    it 'creates generate_series length User records' do
      expect { subject }.to change { User.count }.by(3)
    end
    it 'creates records which contains values specified in block' do
      subject
      User.order(:id).all.each do |user|
        expect(user.name).to eq('name')
        expect(user.age).to eq(16)
        expect(user.birth_date).to eq(Date.new(2000, 1, 1))
        expect(user.disabled).to eq(true)
        expect(user.created_at).not_to be_nil
        expect(user.updated_at).not_to be_nil
      end
    end

    context 'when raw sql is used' do
      let(:block) do
        proc do |sql|
          sql.name = raw("'name' || seq")
          sql.age = raw('seq * 2')
          sql.birth_date = raw("'2000-01-01'::date + seq")
          sql.disabled = raw('CASE seq % 2 WHEN 0 THEN true ELSE false END')
        end
      end

      it 'creates records which contains values specified by raw sql' do
        subject
        User.order(:id).all.each.with_index do |user, i|
          seq = i + 1
          expect(user.name).to eq("name#{seq}")
          expect(user.age).to eq(2 * seq)
          expect(user.birth_date).to eq(Date.new(2000, 1, 1) + seq)
          expect(user.disabled).to eq(seq.even?)
          expect(user.created_at).not_to be_nil
          expect(user.updated_at).not_to be_nil
        end
      end
    end

    context 'with :step option' do
      let(:options) { { step: 2 } }

      it 'forwards generate_series sequence by specified step and creates records' do
        expect { subject }.to change { User.count }.by(2)
      end
    end

    context 'with :seq_name option' do
      let(:options) { { seq_name: :new_seq } }
      let(:block) do
        proc do |sql|
          sql.name = 'name'
          sql.birth_date = Date.new(2000, 1, 1)
          sql.disabled = true

          sql.age = raw('new_seq')
        end
      end

      it 'changes sequence name and creates records with new sequence name' do
        subject
        User.order(:id).all.each.with_index do |user, i|
          seq = i + 1
          expect(user.age).to eq(seq)
        end
      end
    end

    context 'with :debug option' do
      let(:options) { { debug: true } }

      it 'does not create records' do
        expect { subject }.not_to(change { User.count })
      end
    end

    context 'when receiver is sti subclass' do
      subject { AdminUser.insert_using_generate_series(first, last, options, &block) }

      it 'creates generate_series length records with type column' do
        expect { subject }.to change { AdminUser.count }.by(3)
      end
    end
  end
end
