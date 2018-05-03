require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker

  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    def parsed(last_response)
      JSON.parse(last_response.body)
    end

    def setup_post(success, expense_id, error_message)
      allow(ledger).to receive(:record)
        .with(expense)
        .and_return(RecordResult.new(success, expense_id, error_message))
    end

    def setup_get(date, expense_list)
      allow(ledger).to receive(:expenses_on)
        .with(date)
        .and_return(expense_list)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    describe 'POST /expenses' do
      let(:expense) { { 'some' => 'data' } }

      context 'when the expense is successfully recorded' do
        before do
          setup_post(true, 417, nil)
        end

        it 'returns the expense id' do
          post '/expenses', JSON.generate(expense)
          expect(parsed(last_response)).to include('expense_id' => 417)
        end

        it 'repsonds with a 200 (OK)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(200)
        end
      end

      context 'when the expense fails validation' do
        before do
          setup_post(false, 417, 'Expense incomplete')
        end

        it 'returns an error message' do
          post '/expenses', JSON.generate(expense)
          expect(parsed(last_response)).to include('error' => 'Expense incomplete')
        end

        it 'reponds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(422)
        end
      end
    end

    describe 'GET /expenses/:date' do
      context 'when expenses exist on the given date' do
        let(:date) { '2017-06-12' }

        before do
          setup_get(date, ['expense_1', 'expense_2'])
        end

        it 'return the expense records as JSON' do
          get "/expenses/#{date}"
          expect(parsed(last_response)).to eq(['expense_1', 'expense_2'])
        end

        it 'responds with a 200 (OK)' do
          get "/expenses/#{date}"
          expect(last_response.status).to eq(200)
        end
      end

      context 'when there are no expenses on a given date' do
        let(:date) { '2017-08-12' }

        before do
          setup_get(date, [])
        end

        it 'returns an expty array as JSON' do
          get "/expenses/#{date}"
          expect(parsed(last_response)).to eq([])
        end

        it 'responds with a 200 (OK)' do
          get "/expenses/#{date}"
          expect(last_response.status).to eq(200)
        end
      end
    end
  end
end
