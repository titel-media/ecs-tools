require "optparse"
require "yaml"
require "aws-sdk"

def deep_dup(obj)
  Marshal.load(Marshal.dump(obj))
end

class Array
  def deep_symbolize_keys
    map do |object|
      object.respond_to?(:deep_symbolize_keys) ? object.deep_symbolize_keys : object
    end
  end
end

class Hash
  def deep_symbolize_keys
    inject({}) do |hash, (key, value)|
      hash[key.to_sym] = value.respond_to?(:deep_symbolize_keys) ? value.deep_symbolize_keys : value
      hash
    end
  end
end

