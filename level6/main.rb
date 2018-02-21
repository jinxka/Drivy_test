require 'json'
require 'date'

class Main
  def initialize(data_file_name)
    data_file = File.open(data_file_name)
    data = JSON.parse(data_file.read)
    @cars = {}
    data['cars'].each do |car|
      @cars[car['id']] = car
    end
    @rentals = data['rentals']
    @rentalsModif = data['rental_modifications']
  end
  
  def call
    jsonOutput = JSON.pretty_generate(rentalModifPrice)
    File.open('my_output.json', 'w') { |file| file.write(jsonOutput) }
  end
  
  private
  
  def rentalPrice
    rentals = @rentals.collect { |rental| calculatePrice(rental)}
    {rentals: rentals}
  end

  def rentalOption
    rentals = @rentals.collect { |rental| calculateOption(rental)}
    {rentals: rentals}
  end
  
  def rentalModifPrice
    rentalsOption = rentalOption
    updateRentals
    rentalsOptionModif= rentalOption
    compareOptionModif(rentalsOption, rentalsOptionModif)
  end
  
  def compareOptionModif(rentalsOption, rentalsOptionModif)
    rentalsModif= {"rental_modifications": []}
    rentalsOption[:rentals].each_with_index do |rental, rental_index|
      next if rental == rentalsOptionModif[:rentals][rental_index]
      rentalModif = {      "id": rentalsOptionModif[:rentals][rental_index][:id],
                            "rental_id": rental[:id],
                            "actions": []}
      rental[:action].each_with_index do |action, action_index|
        action[:amount] = rentalsOptionModif[:rentals][rental_index][:action][action_index][:amount] - action[:amount]
        action[:type] = action[:type] == "debit" ? "credit" : "debit" if action[:amount] < 0
        action[:amount] *= -1 if action[:amount] < 0
        rentalModif[:actions].push(action)
      end
      rentalsModif[:rental_modifications].push(rentalModif)
    end
    rentalsModif
  end
    
  def updateRentals
    @rentalsModif.each do |rentalModif|
      @rentals.each_with_index { |rental, index|
        if rental['id'] == rentalModif['rental_id']
          @rentals[index].merge!(rentalModif)
          @rentals[index]['id'] = rentalModif['rental_id']
        end
      }
    end
    
  end
  
  def calculateOption(rental)
    bill = calculatePrice(rental)
    {
        id: rental['id'],
        action:[
            {
                "who": "driver",
                "type": "debit",
                "amount": bill[:price] + bill[:option][:deductible_reduction]
            },
            {
                "who": "owner",
                "type": "credit",
                "amount": bill[:price] - (bill[:commission][:insurance_fee] + bill[:commission][:assistance_fee] + bill[:commission][:drivy_fee])
            },
            {
                "who": "insurance",
                "type": "credit",
                "amount": bill[:commission][:insurance_fee]
            },
            {
                "who": "assistance",
                "type": "credit",
                "amount": bill[:commission][:assistance_fee]
            },
            {
                "who": "drivy",
                "type": "credit",
                "amount": bill[:commission][:drivy_fee]+ bill[:option][:deductible_reduction]
            }
        ]
    }
  end
  
  def calculatePrice(rental)
    durationPrice = durationPrice(rental)
    distancePrice = rental['distance'] * @cars[rental['car_id']]['price_per_km']
    price = durationPrice + distancePrice
    commission = calculateCommission(price)
    {
        id: rental['id'],
        price: price,
        option:
            {
                deductible_reduction: deductibleReduction(rental)
            },
        commission: commission
    }
  end
  
  def deductibleReduction(rental)
    return @duration * 400 if rental['deductible_reduction']
    0
  end
  
  def calculateCommission(price)
    commission = price * 0.3
    assistance_fee = @duration * 100
    insurance_fee = (commission * 0.5).to_i
    drivy_fee = insurance_fee - assistance_fee
    {
        "insurance_fee": insurance_fee,
        "assistance_fee": assistance_fee,
        "drivy_fee": drivy_fee
    }
  end

  def durationPrice(rental)
    price_per_day = @cars[rental['car_id']]['price_per_day']
    @duration = (Date.parse(rental['end_date']) - Date.parse(rental['start_date'])).to_i + 1
    durationPrice = 0
    (1..@duration).to_a.each_with_index{ |_, index|
      if index >= 10
        durationPrice += price_per_day * 0.5
      elsif index >= 4
        durationPrice += price_per_day * 0.7
      elsif index >= 1
        durationPrice += price_per_day * 0.9
      else
        durationPrice += price_per_day
      end
    }
    durationPrice.to_i
  end
end
