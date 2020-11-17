# frozen_string_literal: true

require 'date'
require 'json'
require 'link_thumbnailer'
require 'mustache'
require 'slugify'

$posts = {}

LinkThumbnailer.configure do |config|
  config.attributes = [:images]
  config.image_limit = 1
  config.image_stats = false
end

def extract_photo_url(message)
  unless message['photo'].nil?
    return "https://res.cloudinary.com/vast-space-unexplored/image/upload/#{message['photo'].gsub('@', '_')}"
  end
  return nil if message['text'].is_a? String

  message['text'].each do |text_item|
    next if text_item.is_a? String

    case text_item['type']
    when 'text_link'
      link = text_item['href']
      link = "https://#{link}" unless (link.start_with? 'http://') || (link.start_with? 'https://')
      puts link
      begin
        images = LinkThumbnailer.generate(link).images
        return images.first.src.to_s unless images.empty?
      rescue StandardError
        next
      end
    when 'link'
      link = text_item['text']
      link = "https://#{link}" unless (link.start_with? 'http://') || (link.start_with? 'https://')
      puts link
      begin
        images = LinkThumbnailer.generate(link).images
        return images.first.src.to_s unless images.empty?
      rescue StandardError
        next
      end
    else
      next
    end
  end
  nil
end

def message_to_hash(message)
  # puts 'message_to_hash ' + message.to_json
  tags = []
  text = ''
  title = ''
  if message['text'].is_a? String
    text = message['text']
    title = text[0..50]
  else
    text = message['text'].map { |text_item| text_item_to_markup(text_item) }.join('')
    message['text'].each do |text_item|
      break if title.size >= 50

      title += if text_item.is_a? String
                 text_item
               elsif text_item['type'] == 'link'
                 ''
               else
                 text_item['text']
               end
      next unless title.include? "\n"

      #   puts 'changing title from ' + title
      title = (title.split "\n").first
      #   puts 'to ' + title
      break
    end
  end
  title = "#{title[0..50]}..." if title.size > 100
  slug = "#{message['date'][0..9]}-#{title.slugify}"
  filename = "./_posts/#{slug}.md"
  unless message['text'].is_a? String
    message['text'].select do |text_item|
      tags.push text_item['text'][1..] if text_item['type'] == 'hashtag'
    end
  end
  puts title
  $posts[message['id']] = slug
  {
    # 'date' => DateTime.iso8601(message['date']).strftime('%Y-%m-%d %H:%M:%S'),
    'date' => message['date'],
    'filename' => filename,
    'photo' => extract_photo_url(message),
    'tags' => "[#{tags.join ', '}]",
    'text' => text,
    'title' => title
  }
end

def process_link(link)
  if link.start_with? 'https://t.me/vast_space_unexplored'
    post_id = (link.split '/').last.to_i
    return "/#{$posts[post_id]}" if $posts.key? post_id
  end
  link
end

def text_item_to_markup(text_item)
  if text_item.is_a? String
    if text_item == ' | '
      ' \| '
    else
      text_item
    end
  else
    case text_item['type']
    when 'bold'
      "**#{text_item['text']}**"
    when 'hashtag'
      "[#{text_item['text']}](/tags/#{text_item['text']})"
    when 'italic'
      "__#{text_item['text']}__"
    when 'link'
      processed_link = process_link(text_item['text'])
      "[#{processed_link}](#{processed_link})"
    when 'mention'
      "[#{text_item['text']}](https://t.me/#{text_item['text'][1..]})"
    when 'text_link'
      "[#{text_item['text']}](#{process_link(text_item['href'])})"
    else
      text_item['text']
    end
  end
end

template = File.read('./scripts/post.md')
data = File.read('./_data/messages.json')
messages = JSON.parse(data)
messages.each do |message|
  message_data = message_to_hash(message)
  next if message_data['text'].empty?

  post = Mustache.render(template, message_data)
  File.open(message_data['filename'], 'w') do |file|
    file.write(post)
  end
end
