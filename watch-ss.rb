#!/usr/bin/env jruby
# coding: utf-8
# watch sockets status

VERSION = "0.3"

ALLOW = %w{
  ^127\.
  ^10\.
  ^150\.69\.
  ^108\.160\..+80
  \.993$
  \.5223$
  ^131\.206\.4\.50
  ^114\.111\.71\.165
  ^114\.111\.79\.198
  ^124\.83\.135\.162
  ^124\.83\.151\.162
  ^124\.83\.199\.146
  ^124\.83\.238\.249
  ^216\.58\.197\.195
  ^216\.143\.70\.
  ^52\.192\.191\.104
  }.map{|p| %r{#{p}}}

def debug(s)
  STDERR.puts "debug: " + s if $debug
end

def usage
  print <<EOF
usage: $0 [--loop l] [--pause p] [--thres t]
          [--pict path_to_pict]
          [--allow path_to_allow_rules]
          [--version]
EOF
  exit(1)
end

def ss_osx()
  IO.popen("netstat -p tcp -n") do |p|
    p.readlines.select{|l| l =~ /ESTABLISHED$/ }.map{|l| l.split[4]}
  end
end

def ss_linux()
  IO.popen("ss -t -n ") do |p|
    lines = p.readlines
    debug "#{__method__} #{lines.join("\n")}"
    lines.select{|l| l =~ /^ESTAB/}.map{|l| l.split[4]}
  end
end

def match(word, rules)
  rules.each do |r|
    return true if word =~ r
  end
  false
end

class Warn
  include Java

  def initialize(image)
    @display = false
    @frame = javax.swing.JFrame.new("授業中だぞ")
    @frame.setDefaultCloseOperation(javax.swing.JFrame::DO_NOTHING_ON_CLOSE)

    panel = javax.swing.JPanel.new()
    # NG. GridLayout ではコンポーネントの大きさが均一となる。
    # panel.set_layout(java.awt.GridLayout.new(4,1))
    panel.set_layout(
      javax.swing.BoxLayout.new(
      panel,javax.swing.BoxLayout::Y_AXIS))

    p1 = javax.swing.JPanel.new()
    label = javax.swing.JLabel.new("授業と関係ないサイトを開いてないか？")
    button = javax.swing.JButton.new("反省")
    button.add_action_listener do |e|
      @display = false
      @frame.set_visible(@display)
    end
    p1.add(label)
    p1.add(button)
    panel.add(p1)

    if File.exists?(image)
      p2 = javax.swing.JPanel.new()
      p2.add(javax.swing.JLabel.new(javax.swing.ImageIcon.new(image)))
      panel.add(p2)
    end

    p3 = javax.swing.JPanel.new()
    p3.add(javax.swing.JLabel.new("* 接続中のサイト *"))
    panel.add(p3)

    p4 = javax.swing.JPanel.new()
    @sites = javax.swing.JTextArea.new
    p4.add(@sites)
    panel.add(p4)

    @frame.add(panel)
    @frame.pack
    @frame.set_visible(false)
  end

  def warn(hosts)
    return if @display
    @sites.setText(hosts.join("\n"))
    @display = true
    @frame.set_visible(true)
  end

  def close
    java.lang.System.exit(0)
  end

end

#
# main starts here
#

case `uname`
when /Darwin/
  alias :ss :ss_osx
when /Linux/
  alias :ss :ss_linux
else
  raise "unknown os:#{`uname`}"
end

$loop = 9999
$pause = 30
$threshold = 10
$rules = ALLOW
$pict = "/edu/lib/watch-ss/warn.jpg"
$no_watch = "/home/t/hkimura/Desktop/no-watch-ss"

$debug = false
while (arg = ARGV.shift)
  case arg
  when /--debug/
    $debug = true
    $loop = 9999
    $pause = 3
    $threshold = 3
    $pict = "./warn.jpg"
    $no_watch = "./no-watch-ss"
    break
  when /--loop/
    $loop = ARGV.shift.to_i
    $loop = 99999 if $loop == 0
  when /--pause/
    $pause = ARGV.shift.to_i
  when /--thres/
    $threshold = ARGV.shift.to_i
  when /--pict/
    $pict = ARGV.shift
  when /--allow/
    $rules = []
    File.foreach(ARGV.shift) do |line|
      next if line=~/^#/
      next if line=~/^\s*$/
      $rules.push %r{#{line.chomp}}
    end
  when /--version/
    puts VERSION
    exit(1)
  else
    usage()
  end
end

debug "$rules: #{$rules}"
warn = Warn.new($pict)

while ($loop > 0)
  sleep $pause
  if File.exists?($no_watch)
    debug "no-watch-ss found"
    next
  else
    debug "check ss()"
  end
  # here is the main part of this script.
  connections = ss()
  debug "ss: #{connections}"
  disallow = connections.find_all{|s| not match(s, $rules)}
  debug "disallow: #{disallow}, count: #{disallow.count}"
  warn.warn(disallow) if disallow.count > $threshold
  #
  $loop -= 1
end

Thread.join
