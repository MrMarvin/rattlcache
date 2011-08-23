require "test/unit"
require "rattlecache"

class MyTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @cache = Rattlecache::Cache.new(:filesystem)
    @prefix = "/tmp/rattlecache/"

  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_flush()
    @cache.flush
    assert(File.directory?(@prefix))
    assert(Dir.entries(@prefix) == [".",".."])
  end


  def test_get_nonexisting_object()
    @cache.flush
    res = @cache.get("http://example.com/some/path/some.file")
    assert_instance_of(Hash,res)
    assert_equal(404,res[:status])
  end

  def test_post()
    @cache.flush
    testobject = {
        :key => "http://example.com/some/path/some.file",
        :header => {"foo" => "bar-thishastobethere-baz", "date" => Time.now(), "content-type" => "text/plain"},
        :data => %{Lorem ipsum dolor sit amet, consetetur sadipscing elitr,
                  sed diam nonumy eirmod tempor invidunt ut labore et dolore
                  magna aliquyam erat, sed diam voluptua. At vero eos et accusam
                  et justo duo dolores et ea rebum. Stet clita kasd gubergren,
                   no sea takimata sanctus est Lorem ipsum dolor sit amet.}
    }
    testobject_key = @cache.sanitize(testobject[:key])
    @cache.post(testobject)
    assert(Dir.entries(@prefix).include?(testobject_key))

    # posting this a second time. What happens than?
    @cache.post(testobject)
    assert(Dir.entries(@prefix).include?(testobject_key))

  end

  def test_get()
    testobject = {
        :key => "http://example.com/some/path/some.file",
        :header => {"foo" => "bar-thishastobethere-baz", "date" => Time.now(), "content-type" => "text/plain"},
        :data => %{Lorem ipsum dolor sit amet, consetetur sadipscing elitr,
                  sed diam nonumy eirmod tempor invidunt ut labore et dolore
                  magna aliquyam erat, sed diam voluptua. At vero eos et accusam
                  et justo duo dolores et ea rebum. Stet clita kasd gubergren,
                   no sea takimata sanctus est Lorem ipsum dolor sit amet.}
    }
    @cache.post(testobject)
    res = @cache.get(testobject[:key])
    assert_instance_of(Hash,res)
    # assert that this is 404, cause the object has no validation information
    assert_equal(404,res[:status])

    testobject[:header] = {
        "foo" => ["bar-thishastobethere-baz"],
        "date" => [Time.now()],
        "content-type" => ["text/plain"],
        "cache-control" => ["max-age=2592000"]
    }

    @cache.post(testobject)
    res = @cache.get(testobject[:key])
    assert_instance_of(Hash,res)
    # assert that this is 200, cause the object has "cache-control" => "max-age=2592000"
    assert_equal(200,res[:status])

  end

end