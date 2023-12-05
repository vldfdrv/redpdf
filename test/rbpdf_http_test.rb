# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

require 'test_helper'

class RbpdfHttpTest < Test::Unit::TestCase
  class MYPDF < RBPDF
    def get_image_file(uri)
      super
    end
  end

  def setup
    require 'webrick'
    @port = 51234

    dir = File.dirname(__FILE__)
    @s = WEBrick::HTTPServer.new(:Port => @port, :DocumentRoot => dir, :BindAddress => "0.0.0.0", :DoNotReverseLookup => true)
    @t = Thread.new { @s.start }
  end

  test "Image get image file test" do
    images = [
      # file_name,                    error_message
      ['logo_rbpdf_8bit.png',         nil],
      ['logo_rbpdf_8bit .png',        nil],
      ['logo_rbpdf_8bit+ .png',       nil],
      ['logo_rbpdf_8bit_no_file.png', /^RBPDF error: Unable to get image width and height: /],
    ]
    # no use
    #if RUBY_VERSION >= '2.0' # Ruby 1.9.2/1.9.3
    #  utf8_japanese_aiueo_str  = "\xe3\x81\x82\xe3\x81\x84\xe3\x81\x86\xe3\x81\x88\xe3\x81\x8a"
    #  images << 'logo_rbpdf_8bit_' + utf8_japanese_aiueo_str + '.png'
    #end

    pdf = MYPDF.new
    images.each_with_index {|image, i|
      pdf.add_page
      #image[0].force_encoding('ASCII-8BIT') if image[0].respond_to?(:force_encoding)
      tmpFile = pdf.get_image_file('http://127.0.0.1:' + @port.to_s + '/' + image[0])

      img_file = tmpFile.path
      assert_not_equal "", img_file
      unless File.exist?(img_file)
        assert false, "file not found. :" + img_file
      end

      if image[1].nil?
        result_img = pdf.image(img_file, 50, 0, 0, '', '', '', '', false, 300, '', true)
        assert_equal i+1, result_img
      else
        err = assert_raise(RBPDFError) { 
          result_img = pdf.image(img_file, 50, 0, 0, '', '', '', '', false, 300, '', true)
        }
        assert_match image[1], err.message
        assert_equal nil, result_img
      end

      no = pdf.get_num_pages
      assert_equal i+1, no

      # remove temp files
      tmpFile.delete unless tmpFile.nil?

      if File.exist?(img_file)
        assert false, "file found. :" + img_file
      end
    }
  end

  def teardown
    @s.shutdown
    @t.join
  end
end
