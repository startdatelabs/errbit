class JsMapping
  include Mongoid::Document
  include Mongoid::Timestamps

  field :fingerprint
  field :minified_url_path
  field :source_map_url_path

  index fingerprint: 1

  def self.find_or_create(minified_url_path)
    fingerprint = generate_fingerprint(minified_url_path)

    find_or_create_by(fingerprint: fingerprint, minified_url_path: minified_url_path)
  end

  def self.generate_fingerprint(minified_url_path)
    Digest::SHA1.hexdigest(minified_url_path)
  end

  private
  def generate_fingerprint
    self.fingerprint = self.class.generate_fingerprint(minified_url_path)
  end
end
