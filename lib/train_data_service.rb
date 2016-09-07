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
    @train = train_with_id request[:train_id]
    reservation = 
      if @train.overbooked?(request)
        no_reservation_on request[:train_id]
      else
        make_reservation request
      end

    response = @train_data_api.reserve reservation

    if response=~/already booked/
      return no_reservation_on(request[:train_id])
    end

    reservation
  end

  private

  def train_with_id train_id
    seats_doc = JSON.parse(
      @train_data_api.seats_for(train_id), symbolize_names: true)[:seats]

    Train.new(seats_doc.map { |_id, seat| Seat.new seat })
  end

  def make_reservation request
    {
      train_id: request[:train_id],
      booking_reference: @booking_reference.new_reference_number,
      seats: @train.free_seats(request[:seats])
    }
  end

  def no_reservation_on train
    { train_id: train, booking_reference: '', seats: [] }
  end

  class Train
    def initialize seats
      @seats_on_train = seats.sort_by { |seat| seat.seat_number }
    end

    def overbooked? request
      number_booked =
        @seats_on_train.count { |seat| seat.booked? } + request[:seats]

      Rational(number_booked, @seats_on_train.size) > 70.percent
    end

    def free_seats number
      free_seats = 
        @seats_on_train.select { |seat| seat.free? }.map { |seat| seat.id }

      free_seats.first(number)
    end
  end

  class Seat
    def initialize args
      @args = args
    end

    def seat_number
      @args[:seat_number]
    end

    def id
      "#{@args[:seat_number]}#{@args[:coach]}"
    end

    def booked?
      @args[:booking_reference].size > 0
    end

    def free?
      !booked?
    end
  end
end
