require 'json'
describe 'Train Data Service' do
  class TrainDataService
    def initialize(train_data_api, booking_reference_service)
      @train_data_api = train_data_api
      @booking_reference = booking_reference_service
    end

    def reserve_seats request
      @seats_on_train = 
        JSON.parse(@train_data_api.seats_for(request[:train_id]))['seats']
      if @seats_on_train.all? { |_id, seat| booked? seat }
       return  no_reservation_on request[:train_id]
      end

      {
        train_id: request[:train_id],
        booking_reference: @booking_reference.new_reference_number,
        seats: free_seats(1)
      }
    end

    private

    def free_seats number
      free_seats = @seats_on_train.select { |_id, seat| free? seat }

      free_seats.keys.first number
    end

    def no_reservation_on train
      { train_id: train, booking_reference: '', seats: [] }
    end

    def free? seat
      seat['booking_reference'].empty?
    end

    def booked? seat
      seat['booking_reference'].size > 0
    end
  end

  describe '#reserve_seats' do
    describe 'reserving a single seat' do
      before :each do 
        @request = { train_id: 'train_1234', seats: 1 }  
      end

      context 'when the train is fully-booked' do
        before :each do
          @train_data_api = double :train_data_api
          @train_data_service = TrainDataService.new(@train_data_api, nil)
        end

        it 'does not reserve the seat' do
          allow(@train_data_api).to(
            receive(:seats_for).with('train_1234').and_return(
              seats_doc(booked(1, 'A'), booked(2, 'A'), booked(3, 'A')) 
            )
          )

          reservation = @train_data_service.reserve_seats @request

          expect(reservation).not_to be_made_on 'train_1234'
        end

        def seats_doc *seats
          { 'seats' => Hash[seats] }.to_json
        end

        def booked(seat_number, coach)
          [
            "#{seat_number}#{coach}", {
               'booking_reference' => 'ref_number',
               'seat_number' => seat_number,
               'coach' => coach
            }
          ]
        end

        RSpec::Matchers.define :be_made_on do |train|
          match_when_negated do |reservation|
            reservation == no_reservation_on(train)
          end
          
          def no_reservation_on train
            { train_id: train, booking_reference: '', seats: [] }
          end

          failure_message_when_negated do |reservation|
            seats = reservation[:seats].join ','
            booking_reference = reservation[:booking_reference]
            message = "Expected no reservation to be made on #{train}, but "
            message << "seats #{seats} were booked "
            message << "under reference number #{booking_reference}"
            message
          end
        end
      end

      context 'when the train has no existing reservations' do
        before :each do
          booking_reference =
            double(:booking_reference,
                   new_reference_number: 'a_reference_number')
          @train_data_service = TrainDataService.new(
            @train_data_api, booking_reference
          )
        end
        it 'reserves the first available seat' do
          allow(@train_data_api).to(
            receive(:seats_for).with('train_1234').and_return(
              seats_doc(free(1, 'A'), free(2, 'A'), free(3, 'A')) 
            )
          )

          reservation = @train_data_service.reserve_seats @request

          expect(reservation).to(
            eq(
              train_id: 'train_1234',
              booking_reference: 'a_reference_number',
              seats: %w{1A}
            )
          )
        end

        
        def seats_doc *seats
          { 'seats' => Hash[seats] }.to_json
        end

        def free(seat_number, coach)
          [
            "#{seat_number}#{coach}",
            {
              'booking_reference' => '',
              'seat_number' => seat_number,
              'coach' => coach
            }
          ]
        end

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
