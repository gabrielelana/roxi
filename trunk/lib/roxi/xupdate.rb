
require 'roxi'
require 'roxi/xpath'
require 'roxi/xupdate/xupdate'

module ROXI::XContainer
  def update(&block)
    ROXI::XUpdate.update(self, &block)
  end
end
