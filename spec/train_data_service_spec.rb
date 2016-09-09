require 'json'
require 'train_data_service'
describe 'Train Data Service' do
  describe '#reserve_seats' do
    before(:each) do
      @train_data_api = double :train_data_api 
      booking_reference =
        double(:booking_reference, new_reference_number: 'a_reference_number')
      @train_data_service = 
        TrainDataService.new(@train_data_api, booking_reference)
    end
    
    describe 'reserving a single seat' do
      before :each do 
        @request = { train_id: 'train_1234', seats: 1 }  
      end

      context 'when the train is fully-booked' do
        before :each do
          allow(@train_data_api).to(
            receive(:seats_for).with('train_1234').and_return(
              seats_doc(booked(1, 'A'), booked(2, 'A'), booked(3, 'A'))))
        end

        it 'does not reserve the seat' do
          expect(@train_data_api).to(
            receive(:reserve).with(
              booking_reference: '', train_id: 'train_1234', seats: %w{}))

          reservation = @train_data_service.reserve_seats @request

          expect(reservation).not_to be_made_on 'train_1234'
        end
      end

      context 'when the train has no existing reservations' do
        before :each do
          allow(@train_data_api).to(
            receive(:seats_for).with('train_1234').and_return(
              seats_doc(free(1, 'A'), free(2, 'A'), free(3, 'A'))
          ))
        end
        
        it 'reserves the first available seat' do
          expect(@train_data_api).to(
            receive(:reserve).with(
              booking_reference: 'a_reference_number',
              train_id: 'train_1234', seats: %w{1A}))
          
          @train_data_service.reserve_seats @request
        end

        describe 'when the request is successful' do
          it 'returns the reservation that was made' do
            allow(@train_data_api).to(
              receive(:reserve).with(
                booking_reference: 'a_reference_number',
                train_id: 'train_1234', seats: %w{1A}))
          
            reservation = @train_data_service.reserve_seats @request

            expect(reservation).to be_made_on('train_1234').for_seats '1A'
          end
        end

        describe 'when someone else ends up reserving the seat first' do
          it 'does not reserve the seat' do
            reservation = {
              booking_reference: 'a_reference_number',
              train_id: 'train_1234', seats: %w{1A}
            }
            allow(@train_data_api).to(
              receive(:reserve).with(reservation).and_return(
              'already booked with reference: existing'
            ))
            
            reservation = @train_data_service.reserve_seats @request
            
            expect(reservation).not_to be_made_on 'train_1234'
          end
        end
      end
      
      context 'when the train is under 70% reserved' do
        context 'and remains so after the reservation' do
          before :each do
            allow(@train_data_api).to(
              receive(:seats_for).with('train_1234').and_return(
                seats_doc(booked(1, 'A'), free(2, 'A'), free(3, 'A'))
            ))
          end
          
          it 'reserves the first available seat' do
            expect(@train_data_api).to receive(:reserve).with(
              train_id: 'train_1234', booking_reference: 'a_reference_number',
              seats: %w{2A}
            )

            reservation = @train_data_service.reserve_seats @request

	    expect(reservation).to be_made_on('train_1234').for_seats '2A'
          end
        end

        context 'but ends up being > 70% reserved after the booking' do
          before :each do
            allow(@train_data_api).to(
              receive(:seats_for).with('train_1234').and_return(
                seats_doc(booked(1, 'A'), free(2, 'A'), booked(3, 'A'))
            ))
          end

          it 'does not reserve the seat' do
            expect(@train_data_api).to(
              receive(:reserve).with(
                booking_reference: '', train_id: 'train_1234', seats: %w{}))
      
            reservation = @train_data_service.reserve_seats @request

            expect(reservation).not_to be_made_on 'train_1234'
          end
        end

        context 'and becomes exactly 70% reserved after the booking' do
          before :each do
            allow(@train_data_api).to(
              receive(:seats_for).with('train_1234').and_return(
                seats_doc(
                  booked(1, 'A'), booked(2, 'A'), booked(3, 'A'),
                  booked(4, 'A'), booked(5, 'A'), booked(6, 'A'),
                  free(7, 'A'), free(8, 'A'), free(9, 'A'), free(10, 'A')
                )
            ))
          end

          it 'reserves the first available seat' do
            reservation = {
              train_id: 'train_1234',
              booking_reference: 'a_reference_number',
              seats: %w{7A}
            }
            expect(@train_data_api).to receive(:reserve).with reservation

            @train_data_service.reserve_seats @request
          end
        end
      end

      describe 'multiple carriages' do
        context 'when a carriage is completely free' do
          before :each do
            allow(@train_data_api).to(
              receive(:seats_for).with('train_1234').and_return(
                seats_doc(
                  booked(1, 'A'), booked(2, 'A'), booked(3, 'A'),
                  booked(4, 'A'), booked(5, 'A'), 
                  free(1, 'B'), free(2, 'B'), free(3, 'B'),
                  free(4, 'B'), free(5, 'B')
                )
              ))
          end

          it 'reserves the seat' do
             expect(@train_data_api).to(
               receive(:reserve).with(hash_including(seats: %w{1B})))

             @train_data_service.reserve_seats @request
          end
        end

        context 'when a carriage is under 70% reserved' do
          context 'and remains so after the booking' do
            before :each do
              allow(@train_data_api).to(
                receive(:seats_for).with('train_1234').and_return(
                  seats_doc(
                    free(1, 'A'), booked(2, 'A'), booked(3, 'A'),
                    booked(4, 'A'), booked(5, 'A'), 
                    free(1, 'B'), free(2, 'B'), free(3, 'B'),
                    free(4, 'B'), free(5, 'B')
                  )
                ))
            end
            
            it 'reserves the seat' do
               expect(@train_data_api).to(
                 receive(:reserve).with(hash_including(seats: %w{1B})))

               @train_data_service.reserve_seats @request
            end
          end
        end
      end
    end  

    describe 'booking multiple seats' do
      context 'when the train can accommodate the booking' do
        before :each do
          allow(@train_data_api).to(
            receive(:seats_for).with('train_1234').and_return(
              seats_doc(
                booked(1, 'A'), free(5, 'A'), free(4, 'A'),
                free(3, 'A'), free(2, 'A'), free(6, 'A')
              )
          ))
        end

        it 'books all the seats in one carriage' do
          request = { train_id: 'train_1234', seats: 3 }
          
	  expect(@train_data_api).to(
            receive(:reserve).with(hash_including(seats: %w{2A 3A 4A})))

          @train_data_service.reserve_seats request            
        end
      end
    end

    describe 'multiple carriages' do
      context 'when the train is under 70% booked' do
        context 'but ends up being > 70% reserved after the booking' do
          it 'does not reserve the seat'
        end

        context 'and becomes exactly 70% reserved after the booking' do
          it 'reserves the seat'
        end
      end
    end
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

  def booked(seat_number, coach)
    [
      "#{seat_number}#{coach}",
      {
        'booking_reference' => 'ref_number',
        'seat_number' => seat_number,
        'coach' => coach
      }
    ]
  end

  RSpec::Matchers.define :be_made_on do |train|
    match do |reservation|
      reservation[:seats] == @seats and
        reservation[:train_id] == train and
        reservation[:booking_reference].size > 0
    end
    
    chain :for_seats do |*seats|
      @seats = seats
    end

    failure_message do |reservation|
      actual_train = reservation[:train_id]
      seats = reservation[:seats].join ','
      booking_reference = reservation[:booking_reference]
      message = "Expected reservation to be made on '#{train}' "
      message << "for seats #{@seats.join(',')} but\n"
      message << "a reservation was made on '#{actual_train}' for "
      message << "seats #{seats} under ref no. #{booking_reference}"
      message
    end
    
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
