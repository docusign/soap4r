=begin
WSDL4R - XMLSchema attribute definition for WSDL.
Copyright (C) 2002 NAKAMURA Hiroshi.

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


require 'wsdl/info'


module WSDL
  module XMLSchema


class Attribute < Info
  attr_reader :ref
  attr_reader :arrayType

  def initialize
    super
    @ref = nil
    @arrayType = nil
  end

  def parseElement( element )
    nil
  end

  RefAttrName = Name.new( nil, 'ref' )
  ArrayTypeAttrName = Name.new( Namespace, 'arrayType' )
  def parseAttr( attr, value )
    case attr
    when RefAttrName
      @ref = value
    when ArrayTypeAttrName
      @arrayType = if value.is_a?( Name )
	  value
	else
	  Name.new( XSD::Namespace, value )
	end
    else
      raise WSDLParser::UnknownAttributeError.new( "Unknown attr #{ attr }." )
    end
  end
end

  end
end