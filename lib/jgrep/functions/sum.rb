function(:sum) do |args|
  args.reduce(0) { |x,y| x + y}
end
