require 'rubygems'
require 'bundler/setup'

@game_id = "869222"
@url = "http://www.boiteajeux.net/jeux/agr/partie.php?id=#{@game_id}"
@history_url = "http://www.boiteajeux.net/jeux/agr/historique.php?id=#{@game_id}"




class HttpFetcher
  require 'open-uri'
  def fetch(url)
    puts "Fetching #{url}"
    open(url).read
  end
end


class PageParser
  require 'nokogiri'
  def find_nickname_in_a_page(data)
    page = Nokogiri::HTML(data)
    its_player_turn = page.css("td[class='clInfo']").text
    match = /It's (?<nick>.*)'s turn !/.match(its_player_turn)
    if match
      match[:nick]
    end
  end

  def find_game_over_in_a_page(data)
    page = Nokogiri::HTML(data)
    match = /GAME OVER/.match(page.text)
    if match
      true
    else
      false
    end
  end

  def find_history_in_a_page(data)
    page = Nokogiri::HTML(data)

    nicks = find_nicks(page)
    puts "Nicks found: #{nicks}"

    moves = find_moves(page, nicks)
    puts "Moves: #{moves.length}"

    moves
  end

  def find_moves(page, nicks)
    moves = {}
    history_table = find_table_with_history(page)
    rows = history_table.css("tr")
    rows.to_enum.with_index do |tr, index|
      if index == 0 #tr with thead "nicks"
        next
      end

      tds_with_moves = tr.children
      if row_contains_round_number(tr, nicks)
        tds_with_moves = tr.children[1..tr.children.length]
      end

      tds_with_moves.to_enum.with_index do |td, td_index|
        move_number, move_description = parse_td_with_move_description(td)
        nick = nick_by_number(nicks, td_index)
        if move_number
          puts "#{move_number}: #{nick}: #{move_description}"
          moves[move_number] = {
              :number => move_number,
              :nick => nick,
              :description => move_description
          }
        end
      end
    end
    moves
  end

  def row_contains_round_number(tr, nicks)
    tr.children.length == nicks.length + 1
  end

  def nick_by_number(nicks, number)
    if nicks and nicks.length > 0
      nicks[number]
    else
      nil
    end
  end

  def parse_td_with_move_description(td)
    number = 0
    text = ''
    if td.children.length < 2
      return nil, nil
    end
    td.children.to_enum.with_index do |child, index|
      #puts "Parsing td child: #{child.text}"
      if index == 0
        number = child.text.to_i
        #puts "NUMBER: #{number}"
        next
      end

      if child.name == 'img'
        text << "<#{MoveBeautifier.convert(child.attributes['src'].text)}>"
      else
        text << "#{child.text}"
      end
    end
    #puts "TEXT: #{text}"
    return number, text
  end

  def find_nicks(page)
    header = page.css("th[class='clHisto clHistoFonce']")
    label = "Round #"
    nick_nodes = header.children
    if nick_nodes.length <= 1 or nick_nodes[0].text != label
      raise "Something bad. Only 1 player? No label? #{nick_nodes[0].text}"
    end

    nicks = []
    nick_nodes.each do |node|
      index = 0
      if node.name == 'text' and node.text != label
        nicks << node.text.strip
      end
    end
    nicks
  end

  def find_table_with_history(page)
    tables = page.css('table')
    if tables.length != 2
      raise "Expecting 2 tables inside html"
    end
    tables[1]
  end
end

class MoveBeautifier
  def self.convert(value)
    value.
        gsub("img/pionBois16.png", "wood").
        gsub("img/pionPN16.png", "food").
        gsub("img/1stJ.gif", "1st").
        gsub("img/pionRoseau16.png", "reed").
        gsub("img/pionPierre16.png", "stone").
        gsub("img/pionArgile16.png", "clay").
        gsub("img/pionCereale16.png", "grain").
        gsub("img/pionLegume16.png", "veg").
        gsub("img/pionBoeuf16.png", "cow").
        gsub("img/pionSanglier16.png", "pig").
        gsub("img/pionMouton16.png", "sheep")
  end
end


html = HttpFetcher.new.fetch(@history_url)
page_parser = PageParser.new
page = Nokogiri::HTML(html)
nicks = page_parser.find_nicks(page)
page_parser.find_moves(page, nicks)
