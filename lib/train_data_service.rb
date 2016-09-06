require 'json'
class Fixnum
  def percent
    Rational(self, 100)
  end
end

class TrainDataService
  def initialize(train_data_api, booking_reference_service)
    @train_data_api = train_data_api
    @booking_reference = booking_reference_service
  end

  def reserve_seats request
    @seats_on_train = seats_on request[:train_id]

    if percentage_including(request) > 70.percent
      return no_reservation_on request[:train_id]
    end

    reservation = {
      train_id: request[:train_id],
      booking_reference: @booking_reference.new_reference_number,
      seats: first_available_seat(request[:seats])
    }

    response = @train_data_api.reserve reservation

    if response=~/already booked/
      return no_reservation_on(request[:train_id])
    end

    reservation
  end

  private

  def seats_on train_id 
    seats_doc = JSON.parse(@train_data_api.seats_for(train_id))['seats']
    seats_doc
      .map { |_id, seat| Seat.new seat }
      .sort_by { |seat| seat.seat_number }    
  end

  def percentage_including request
    number_booked = 
      @seats_on_train.count { |seat| seat.booked? } + request[:seats]

    Rational(number_booked, @seats_on_train.size)
  end

  def first_available_seat number
    free_seats = @seats_on_train.select { |seat| seat.free? }

    free_seats.first(number).map { |seat| seat.id }
  end

  def no_reservation_on train
    { train_id: train, booking_reference: '', seats: [] }
  end

  class Seat
    def initialize args
      @args = args
    end

    def seat_number
      @args['seat_number']
    end

    def id
      "#{@args['seat_number']}#{@args['coach']}"
    end

    def booked?
      @args['booking_reference'].size > 0
    end

    def free?
      @args['booking_reference'].empty?
    end
  end
end
