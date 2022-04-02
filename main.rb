require 'pry-byebug'
require 'json'

module JSONable
  def to_json(obj = nil)
    hash = {}
    instance_variables.each do |var|
      hash[var] = instance_variable_get var
    end
    hash.to_json
  end

  def from_json! string
    JSON.load(string).each do |var, val|
      instance_variable_set var, val
    end
  end
end

class String
  def letter?
    match?(/[a-z]|[A-Z]/)
  end
end

class Hangman
  include JSONable

  attr_accessor :rand_word, :hid_word, :used, :guesses, :ongoing_game

  WORDS = IO.readlines('google-10000-english-no-swears.txt', chomp: true)

  def initialize
    @rand_word = WORDS.sample
    @used = []
    @guesses = 6
    @ongoing_game = true
  end

  def hide_word
    @hid_word = @rand_word.split('')
    @hid_word.map! { |w| w = '_' }
    @hid_word = @hid_word.join('')
  end

  def input_get(input)
    if @rand_word.include?(input)
      char_index = @rand_word.split('').each_index.select { |index| @rand_word[index] == input }
      char_index.each { |ind| @hid_word[ind] = input }
      @used.push(input)
      true
    else
      puts 'Wrong guess'
      @used.push(input)
      false
    end
  end

  def check_win
    return true if @hid_word == rand_word
  end

  def restart_game
    puts 'Do you want to play again? y/n'
    puts '*********************************************************'
    try_again = gets.chomp.downcase
    case try_again
    when 'y'
      initialize
      hide_word
    when 'n'
      exit(0)
    else
      puts 'Wrong input'
    end
  end

  def check_win_message
    puts "You have #{guesses} guesses remaining"
    if check_win
      puts "Congratulations, you won!\nThe word was '#{rand_word}'"
      self.ongoing_game = false
    elsif guesses.zero?
      puts "You lost, try again\nThe word was '#{rand_word}'"
      self.ongoing_game = false
    end
  end

  def play
    @inp = ''
    save = ''
    loop do
      p hid_word
      puts "Letters used: #{used}" if used.empty? == false
      puts 'Insert a single letter'
      @inp = gets.chomp.downcase
      if @inp.length == 1 && @inp.letter? && used.include?(@inp) == false
        break
      elsif used.include?(@inp)
        puts 'This letter is already used'
      elsif @inp == rand_word
        self.hid_word = @inp
        break
      elsif @inp == '*'
        save_game
      else
        puts 'Wrong input'
      end
    end
    @guesses -= 1 if input_get(@inp) == false
    puts '*********************************************************'
  end

  def load_game
    File.open('Savegames/save.json', 'r') { |file| from_json!(file) }
  end

  def save_game
    puts 'Save game? y/n'
    save = gets.chomp
    if save == 'y'
      Dir.mkdir('Savegames') unless File.exist?('Savegames')
      File.open('Savegames/save.json', 'w') do |file|
        file.write(to_json)
      end
    elsif save == 'n'
    else
      puts 'Wrong input'
      save_game
    end
  end

  def start_game
    puts 'Load game? y/n'
    op = gets.chomp
    if op == 'y'
      load_game
    else
      hide_word
    end
    loop do
      restart_game while ongoing_game == false
      play
      check_win_message
    end
  end
end

new_game = Hangman.new
new_game.start_game
