describe 'Ticket office' do
  class TicketOffice
    def initialize train_data_service
      @train_data_service = train_data_service
    end

    def make_reservation request
      @train_data_service.reserve_seats request
    end
  end
  
  describe '#make_reservation' do
    it 'makes a reservation for the given request' do
      request = { train_id: 'train_1234', seats: 1 }
      train_data_service = double :train_data_service
      expect(train_data_service).to receive(:reserve_seats).with request

      TicketOffice.new(train_data_service).make_reservation request
    end

    it 'returns a JSON document detailing the reservation made'
    it 'reserves any number of seats on any train'
  end
end
