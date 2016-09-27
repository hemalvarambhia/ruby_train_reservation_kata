require 'json'
class Fixnum
  def percent
    Rational(self, 100)
  end
end

class ReservationService
  def initialize(train_data_service, booking_reference_service)
    @train_data_service = train_data_service
    @booking_reference = booking_reference_service
  end

  def reserve_seats request
    @train = train_with_id request[:train_id]
    coach = @train.find { |coach| coach.underbooked? request }
    reservation = 
      if coach.nil?
        no_reservation_on request[:train_id]
      else
        make_reservation(request, coach)
      end

    response = @train_data_service.reserve reservation

    if response=~/already booked/
      return no_reservation_on(request[:train_id])
    end

    reservation
  end

  private

  def train_with_id train_id
    seats_doc = JSON.parse(
      @train_data_service.seats_for(train_id), symbolize_names: true)[:seats]
    all_seats = seats_doc.map { |_, seat| Seat.new seat }
    all_seats.group_by { |seat| seat.coach }.map do |_, seats|
      Coach.new seats
    end
  end

  def make_reservation(request, coach)
    {
      train_id: request[:train_id],
      booking_reference: @booking_reference.new_reference_number,
      seats: coach.first_free_seats(request[:seat_count])
    }
  end

  def no_reservation_on train
    { train_id: train, booking_reference: '', seats: [] }
  end

  class Coach
    def initialize seats
      @seats = seats.sort_by { |seat| seat.seat_number }
    end

    def first_free_seats number
      @seats.select { |seat| seat.free? }.map { |seat| seat.id }
        .first number
    end

    def underbooked? request
      number_booked =
        @seats.count { |seat| seat.booked? } + request[:seat_count]

      Rational(number_booked, @seats.size) <= 70.percent
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
