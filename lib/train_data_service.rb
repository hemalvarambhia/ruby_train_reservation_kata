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
        free_seats = 
          first_free_seats(request)
        make_reservation(request, free_seats)
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

    Train.new(seats_doc.map { |_, seat| Seat.new seat })
  end
  
  def first_free_seats request
    coach, seats = @train.first_underbooked_carriage request

    seats.select { |seat| seat.free? }.map { |seat| seat.id }
      .first request[:seats] 
  end

  def make_reservation(request, seats)
    {
      train_id: request[:train_id],
      booking_reference: @booking_reference.new_reference_number,
      seats: seats #@train.free_seats(request[:seats])
    }
  end

  def no_reservation_on train
    { train_id: train, booking_reference: '', seats: [] }
  end

  class Train
    def initialize seats
      @seats_on_train = seats.sort_by { |seat| seat.seat_number }
    end

    def first_underbooked_carriage request
      seats_by_coach = @seats_on_train.group_by { |seat| seat.coach }
      coach, seats = 
        seats_by_coach.find do |coach, seats|
          underbooked?(request, seats)
        end 
    end

    def underbooked?(request, seats)
      number_booked = seats.count { |seat| seat.booked? } + request[:seats]

      Rational(number_booked, seats.size) <= 70.percent
    end

    def seats_by_coach
      @seats_on_train.group_by { |seat| seat.coach }
    end

    def overbooked? request
      number_booked =
        @seats_on_train.count { |seat| seat.booked? } + request[:seats]

      Rational(number_booked, @seats_on_train.size) > 70.percent
    end

  end

  class Seat
    def initialize args
      @args = args
    end

    def seat_number
      @args[:seat_number]
    end

    def coach
      @args[:coach]
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
