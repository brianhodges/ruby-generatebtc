  require 'rubygems'
  require 'bundler/setup'
  require 'bitcoin'
  require 'rqrcode'
  require 'scrypt'
  
  yes = 'y'
  br = '<br>'
  css = '<style>
    table {
      border-width: 0;
      border-style: none;
      border-color: #0000ff;
      border-collapse: collapse;
    }
    td {
      border-left: solid 4px #000;
      padding: 0; 
      margin: 0; 
      width: 0px; 
      height: 4px; 
    }
    td.black { border-color: #000; }
    td.white { border-color: #fff; }
  </style>'
  
  # Random Filename
  s = SecureRandom.base64 10
  filename = s.gsub(/\W/, 'x') + '.html'
  
  # Generate Pub/Priv Key Pair
  @key = Bitcoin::Key.generate
  
  # Prompt User for BIP-0038 Encryption
  puts
  puts "Enter a BIP38 Password? [y/n]"
  opt = gets.chomp
  if (opt.downcase == yes)
    puts
    puts "Password:"
    password = gets.chomp
    bip38_priv = @key.to_bip38(password)
  end
  
  # Get Addresses from Key
  a1 = Bitcoin.hash160(@key.pub_uncompressed)
  a2 = Bitcoin.hash160(@key.pub)
  @address = Bitcoin.hash160_to_address(a1)
  @address_compressed = Bitcoin.hash160_to_address(a2)
  
  # QR Codes
  @qr_address = RQRCode::QRCode.new(@address.to_s)
  @qr_address_compressed = RQRCode::QRCode.new(@address_compressed.to_s)
  @qr_priv_key = RQRCode::QRCode.new(@key.priv.to_s)
  @qr_priv_key_bip38 = RQRCode::QRCode.new(bip38_priv) unless !bip38_priv
  
  # Open new HTML File to Write to
  f = File.new(filename, "w+")
  
  #Error Handle the Writting/Displaying/Closing of File
  begin
    f.puts "<html><body>" + css
    f.puts "<strong>Address:</strong>" + br + @address.to_s + br
    f.puts @qr_address.as_html + br
    f.puts "<strong>Address (compressed):</strong>" + br + @address_compressed.to_s + br
    f.puts @qr_address_compressed.as_html + br
    f.puts br * 2
    f.puts "<strong>Public Key:</strong>" + br + @key.pub_uncompressed + br
    f.puts "<strong>Public Key (compressed):</strong>" + br + @key.pub + br
    f.puts br * 2
    if !bip38_priv && !@qr_priv_key_bip38
      f.puts "<strong>Private Key:</strong>" + br + @key.priv + br
      f.puts @qr_priv_key.as_html
    else
      f.puts "<strong>Private Key (BIP38 Encrypted):</strong>" + br + bip38_priv + br
      f.puts @qr_priv_key_bip38.as_html
    end
    f.puts br
    f.puts "</body></html>"
    f.close()
    
    # Open & Display Written HTML File - Then Delete
    system("open #{filename}")
    sleep 1
    File.delete(filename)
    
  rescue SystemCallError
    $stderr.print "IO failed: " + $!
    f.close()
    File.delete(filename)
    raise
  end