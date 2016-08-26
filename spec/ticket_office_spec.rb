require 'json'
describe 'Ticket office' do
  class TicketOffice
    def initialize train_data_service
      @train_data_service = train_data_service
    end

    def make_reservation request
      @train_data_service.reserve_seats(request).to_json
    end
  end
  
  describe '#make_reservation' do
    before :each do
      @train_data_service = double :train_data_service
      @ticket_office = TicketOffice.new @train_data_service
    end

    it 'makes a reservation for the given request' do
      request = { train_id: 'train_1234', seats: 1 }
      expect(@train_data_service).to receive(:reserve_seats).with request

      @ticket_office.make_reservation request
    end

    it 'returns a JSON document detailing the reservation made' do
      request = { train_id: 'train_1234', seats: 1 }
      reservation = {
        train_id: 'train_1234', booking_reference: 'abc', seats: %w{1A}
      }
      allow(@train_data_service).to(
        receive(:reserve_seats).with(request).and_return reservation)

      reservation_doc = @ticket_office.make_reservation request

      expect(reservation_doc).to eq reservation.to_json
    end

    it 'reserves any number of seats on any train'
  end
end
