require 'spec_helper'
require 'ticket_office'
describe 'Ticket office' do
  describe '#make_reservation' do
    before :each do
      @reservation_service = double :reservation_service
      @ticket_office = TicketOffice.new @reservation_service
    end

    it 'makes a reservation for the given request' do
      request = { train_id: 'train_1234', seats: 1 }
      expect(@reservation_service).to receive(:reserve_seats).with request

      @ticket_office.make_reservation request
    end

    it 'returns a JSON document detailing the reservation made' do
      request = { train_id: 'train_1234', seats: 1 }
      reservation = 
        { train_id: 'train_1234', booking_reference: 'abc', seats: %w{1A} }
      allow(@reservation_service).to(
        receive(:reserve_seats).with(request).and_return reservation)

      reservation_doc = @ticket_office.make_reservation request

      expect(reservation_doc).to eq reservation.to_json
    end

    it 'reserves any number of seats on any train' do
      any_request = { train_id: 'express_5432', seats: rand(2..10) }
      expect(@reservation_service).to receive(:reserve_seats).with any_request

      @ticket_office.make_reservation any_request
    end
  end
end
