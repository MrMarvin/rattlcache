require "test/unit"
require "rattlecache"

class CacheTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @cache = Rattlecache::Cache.new()
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_sort_params()
    params = "a=1&z=zzz&car=a,b,or,c&bar=2&1=firstofall"
    sorted_params = "?1=firstofall&a=1&bar=2&car=a,b,or,c&z=zzz"
    assert_equal(sorted_params,@cache.sort_params(params))
  end

  def test_request_type()
    input = "http://eu.battle.net/api/wow/item/25"
    type = "item"
    assert_equal(type,@cache.request_type(input))

    input = "http://eu.battle.net/api/wow/guild/nathrezim/Badeverein%20Orgrimmar?fields=members"
    type = "guild"
    assert_equal(type,@cache.request_type(input))

    input = "http://eu.battle.net/api/wow/auction/data/nathrezim"
    type = /auction.*/
    assert_match(type,@cache.request_type(input))

    input = "http://eu.battle.net/auction-data/nathrezim/auctions.json"
    type = /auction.*/
    assert_match(type,@cache.request_type(input))

    input = "http://eu.battle.net/api/wow/character/nathrezim/schnecke?fields=items"
    type = "character"
    assert_equal(type,@cache.request_type(input))
  end

  def test_needs_request_with_given_time?()
    # an our ago + 30 minutes should be O.K.
    assert(@cache.needs_request_with_given_time?(60*30,Time.now-(60*60)))
  end

  def test_sanitize()
    input = "http://eu.battle.net/api/wow/character/nathrezim/schnecke?fields=items&locale=en_GB"
    exp = "0d85213fdb08da5936e1783f5dde60dbb159164a2d084b157773e3067bcdac88"
    assert_equal(exp,@cache.sanitize(input))

    input_with_unsorted_params = "http://eu.battle.net/api/wow/character/nathrezim/schnecke?locale=en_GB&fields=items"
    assert_equal(@cache.sanitize(input_with_unsorted_params),@cache.sanitize(input))
  end

  def test_has_fields?()
    assert(@cache.has_fields?("http://eu.battle.net/api/wow/character/nathrezim/schnecke?fields=items&locale=en_GB"))
    assert_instance_of(FalseClass,@cache.has_fields?("http://eu.battle.net/api/wow/character/nathrezim/schnecke?locale=en_GB"))
  end

end