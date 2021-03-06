class Backtrace
  include Mongoid::Document
  include Mongoid::Timestamps

  IN_APP_PATH = %r{^\[PROJECT_ROOT\](?!(\/vendor))/?}
  GEMS_PATH = %r{\[GEM_ROOT\]\/gems\/([^\/]+)}
  IN_SW_PATH = %r{/var/data/www/apps/startwire/releases/(\w+)/}
  IN_SW_TEST_PATH = %r{/home/ubuntu/startwire/}
  GEM_BASE_PATH = %r{\[GEM_ROOT\]/bundler/gems/startwire-base-(\w+)}

  field :fingerprint
  field :lines

  index fingerprint: 1

  def self.find_or_create(lines)
    fingerprint = generate_fingerprint(lines)

    where(fingerprint: fingerprint).find_one_and_update(
      { '$setOnInsert' => { fingerprint: fingerprint, lines: lines } },
      return_document: :after, upsert: true)
  end

  def self.generate_fingerprint(lines)
    Digest::SHA1.hexdigest(lines.map(&:to_s).join)
  end

  private def generate_fingerprint
    self.fingerprint = self.class.generate_fingerprint(lines)
  end
end
