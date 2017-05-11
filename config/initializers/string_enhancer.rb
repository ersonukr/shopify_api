require 'iconv'
class String
  def remove_non_ascii
    Iconv.conv('ASCII//IGNORE', 'UTF8', self)
  end
end