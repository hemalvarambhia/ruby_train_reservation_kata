require 'json'
describe 'Train Data Service' do
  class TrainDataService
    def initialize(train_data_api, booking_reference_service)
      @train_data_api = train_data_api
    end

    def reserve_seats request
      seats_on_train = 
        JSON.parse(@train_data_api.seats_for(request[:train_id]))['seats']
      if seats_on_train.all? { |_id, seat| booked? seat }
        no_reservation_on request[:train_id]
      end      
    end

    private 

    def no_reservation_on train
      { train_id: train, booking_reference: '', seats: [] }
    end

    def booked? seat
      seat['booking_reference'].size > 0
    end
  end

  before :each do
    @train_data_api = double :train_data_api
    @train_data_service = TrainDataService.new(@train_data_api, nil)
  end

  describe '#reserve_seats' do
    describe 'reserving a single seat' do
      before(:each) do 
        @request = { train_id: 'train_1234', seats: 1 }  
      end

      context 'when the train is fully-booked' do
        it 'does not reserve the seat' do
          allow(@train_data_api).to(
            receive(:seats_for).with('train_1234').and_return(
              seats_doc(booked(1, 'A'), booked(2, 'A'), booked(3, 'A')) 
            )
          )

          reservation = @train_data_service.reserve_seats @request

          expect(reservation).to eq no_reservation_on('train_1234')
        end

        def seats_doc *seats
          { 
            'seats' => seats.inject({}){ |doc, seat| doc.merge seat }
          }.to_json
        end

        def booked(seat_number, coach)
          {
            "#{seat_number}#{coach}" => {
               'booking_reference' => 'ref_number',
               'seat_number' => seat_number,
               'coach' => coach
            }
          }
        end

        def no_reservation_on train
          { train_id: train, booking_reference: '', seats: [] }
        end
      end

      context 'when the train has no existing reservations' do
        it 'reserves the first available seat'
      end
      
      context 'when the train is under 70% reserved' do
        context 'and remains so after the reservation' do
          it 'reserves the first available seat'
        end

        context 'but ends up being > 70% reserved after the booking' do
          it 'does not reserve the seat'
        end

        context 'and becomes 70% reserved after the booking' do
          it 'reserves the first available seat'
        end
      end
    end
  end
end
