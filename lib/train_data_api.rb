require 'net/http'
class TrainDataAPI
  def initialize uri
    @uri = uri
  end

  def seats_for train_id
    Net::HTTP.get(URI("#{@uri}/data_for_train/#{train_id}"))
  end
end