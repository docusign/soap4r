=begin
SOAP4R - Stream handler.
Copyright (C) 2000, 2001 NAKAMURA Hiroshi.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PRATICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 675 Mass
Ave, Cambridge, MA 02139, USA.
=end

require 'socket'
require 'timeout'

require 'soap/soap'
require 'http-access'
require 'uri'


module SOAP


class StreamHandler
  public

  attr_reader :endPoint

  def initialize( endPoint )
    @endPoint = endPoint
  end
end


class HTTPPostStreamHandler < StreamHandler
  include SOAP

public

  MediaType = 'text/xml'

  NofRetry = 10       # [times]
  CallTimeout = 300   # [sec]
  ReadTimeout = 300   # [sec]

  def initialize( endPointUri, proxy = nil )
    super( endPointUri )
    @server = URI.create( endPointUri )
    @proxy = proxy
  end

  def send( soapString, soapAction = nil )
    begin
      s = sendPOST( soapString, soapAction )
    rescue PostUnavailableError
      begin
        s = sendMPOST( soapString, soapAction )
      rescue MPostUnavailableError
        raise HTTPStreamError.new( $! )
      end
    end
  end

  private

  def sendPOST( soapString, soapAction )
    retryNo = NofRetry
    drv = nil
    begin
      drv = HTTPAccess.new( @server.host, @server.port, @proxy )
    rescue
      retryNo -= 1
      if retryNo > 0
        puts 'Retrying connection ...' if $DEBUG
        retry
      end
      raise
    end
    action = "\"#{ soapAction }\""
    requestHeaders = { 'SOAPAction' => action, 'Content-Type' => MediaType }

    puts soapString if $DEBUG

    begin
      timeout( CallTimeout ) do
	relative_uri = @server.path.dup
	if @server.query
	  relative_uri << '?' << @server.query
	end
	if @server.fragment
	  relative_uri << '#' << @server.fragment
	end
	drv.request_post( relative_uri, soapString, requestHeaders )
	rh = drv.get_header
	puts rh if $DEBUG
	responseHeaders = {}
	rh.each do | header |
	  /^([^:]+):\s*([^\r]*)\r?\n/ =~ header
	  responseHeaders[ $1.downcase ] = $2
	end
        if ( drv.code == '405' )
          # 405: Method Not Allowed
          raise PostUnavailableError.new( "#{ drv.code }: #{ drv.message }" )
        elsif ( drv.code != '200' )
          #raise HTTPStreamError.new( "#{ drv.code }: #{ drv.message }" )
        elsif ( !responseHeaders.has_key?( 'content-type' ))
          raise HTTPStreamError.new( 'Content-type not found.' )
        elsif ( /^#{ MediaType }(?:;.*)?/ !~ responseHeaders[ 'content-type' ] )
          raise HTTPStreamError.new( 'Illegal content-type: ' << responseHeaders[ 'content-type' ] )
        end
      end
    rescue TimeoutError
      raise HTTPStreamError.new( 'Call timeout' )
    end

    receiveString = ''
    begin
      timeout( ReadTimeout ) do
	drv.get_data( 8124 ) do | data |
	  receiveString << data
	end
      end
    rescue TimeoutError
      raise HTTPStreamError.new( 'Read timeout' )
    end

    puts receiveString if $DEBUG
    receiveString
  end

  def sendMPOST( soapString, soapAction )
    raise NotImplementError.new()

    s = nil
    if (( status == '501' ) or ( status == '510' ))
      # 501: Not Implemented
      # 510: Not Extended
      raise MPostUnavailableError.new( "Status: #{ status }, Reason-phrase: #{ reason }" )
    elsif ( status != '200' )
      raise HTTPStreamError.new( "#{ status }: #{ reason }" )
    end
  end
end


end