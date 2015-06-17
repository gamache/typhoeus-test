# Making Concurrent HTTP Requests in Ruby with Typhoeus

[Typhoeus](https://github.com/typhoeus/typhoeus) is a Ruby library which
wraps libcurl to create an asynchronous HTTP client that can make
multiple requests concurrently from the same Ruby thread.

In a nutshell, Typhoeus uses an object of type `Typhoeus::Hydra` to
coordinate request handling via `#queue` and `#run`.  Requests (instances of
`Typhoeus::Request`) can be queued before and during execution.  These
requests may register a callback with `#on_complete`, in which responses
can be handled.

Executing the requests with `#run` is a blocking operation, during which
no code other than the requests' `on_complete` handlers.

But, these `on_complete` handlers can queue additional requests.  Using
this technique, we can easily control the amount of request concurrency,
like so:

```ruby
concurrency = 10
hydra = Typhoeus::Hydra.new
queue_next_request = lambda do
  req = Typhoeus::Request.new( ... )
  req.on_complete {|resp| queue_next_request.call}
  hydra.queue(req)
end
concurrency.times { queue_next_request.call }
hydra.run
```

This is very convenient!  But it raises the question: how concurrent
can we get before we're spending more time thrashing than working?

## Performance Tests

`Typhoeus::Hydra` ships with a default concurrency limit of 200, so I
made a script to test a given URL at a range of concurrencies.
[Read the source code for the Typhoeus concurrency performance test
here.](typhoeus-test.rb)

Here are some results, first loading a URL with a 133-byte response,
then a URL with a response of about 13KB.

NB: These tests were run on a MacBook Pro in a rather unscientific way.
The script's facilities for repeating tests a number of times have hopefully
smoothed out intermittent blips to give a good picture of relative
performance.

## Results

Requests per second is shown as a line on graphs; CPU percentage is plotted as dots.

### Ruby 2.1.2

#### Short Response

```
$ ./typhoeus-test.rb GET http://short-response.example.com       # 133 bytes
[
  { "concurrency":   1, "requests_per_second":   68.98, "cpu_percentage":   7.4  },
  { "concurrency":   2, "requests_per_second":   93.2,  "cpu_percentage":   8.37 },
  { "concurrency":   3, "requests_per_second":  161.13, "cpu_percentage":  12.59 },
  { "concurrency":   4, "requests_per_second":  233.41, "cpu_percentage":  17.0  },
  { "concurrency":   5, "requests_per_second":  304.86, "cpu_percentage":  20.7  },
  { "concurrency":  10, "requests_per_second":  624.21, "cpu_percentage":  34.81 },
  { "concurrency":  20, "requests_per_second": 1108.17, "cpu_percentage":  50.85 },
  { "concurrency":  40, "requests_per_second": 1377.56, "cpu_percentage":  56.48 },
  { "concurrency":  60, "requests_per_second": 1489.14, "cpu_percentage":  56.43 },
  { "concurrency":  80, "requests_per_second": 1690.68, "cpu_percentage":  66.13 },
  { "concurrency": 100, "requests_per_second": 1493.8,  "cpu_percentage":  57.35 },
  { "concurrency": 120, "requests_per_second": 1597.41, "cpu_percentage":  64.18 },
  { "concurrency": 140, "requests_per_second": 1584.74, "cpu_percentage":  61.88 },
  { "concurrency": 160, "requests_per_second": 1422.99, "cpu_percentage":  59.42 },
  { "concurrency": 180, "requests_per_second": 1269.99, "cpu_percentage":  59.23 },
  { "concurrency": 200, "requests_per_second": 1331.68, "cpu_percentage":  62.02 }
]
```

<div id="mri_short"></div>

#### Medium Response

```
$ ./typhoeus-test.rb GET http://medium-response.example.com  # 13801 bytes
[
  { "concurrency":   1, "requests_per_second":   60.92, "cpu_percentage":   8.79 },
  { "concurrency":   2, "requests_per_second":   89.51, "cpu_percentage":  11.62 },
  { "concurrency":   3, "requests_per_second":  160.21, "cpu_percentage":  19.11 },
  { "concurrency":   4, "requests_per_second":  206.05, "cpu_percentage":  24.36 },
  { "concurrency":   5, "requests_per_second":  254.53, "cpu_percentage":  28.07 },
  { "concurrency":  10, "requests_per_second":  471.2,  "cpu_percentage":  40.74 },
  { "concurrency":  20, "requests_per_second":  519.54, "cpu_percentage":  45.48 },
  { "concurrency":  40, "requests_per_second":  465.34, "cpu_percentage":  43.74 },
  { "concurrency":  60, "requests_per_second":  481.42, "cpu_percentage":  49.69 },
  { "concurrency":  80, "requests_per_second":  409.81, "cpu_percentage":  44.3  },
  { "concurrency": 100, "requests_per_second":  386.23, "cpu_percentage":  45.72 },
  { "concurrency": 120, "requests_per_second":  380.23, "cpu_percentage":  47.3  },
  { "concurrency": 140, "requests_per_second":  399.55, "cpu_percentage":  50.55 },
  { "concurrency": 160, "requests_per_second":  358.66, "cpu_percentage":  49.35 },
  { "concurrency": 180, "requests_per_second":  378.54, "cpu_percentage":  54.54 },
  { "concurrency": 200, "requests_per_second":  378.81, "cpu_percentage":  54.78 }
]
```

<div id="mri_medium"></div>

### JRuby 1.7.19

#### Short Response

```
$ ./typhoeus-test.rb GET http://short-response.example.com       # 133 bytes
[
  { "concurrency":   1, "requests_per_second":   75.7,  "cpu_percentage":  17.39 },
  { "concurrency":   2, "requests_per_second":  134.47, "cpu_percentage":  19.43 },
  { "concurrency":   3, "requests_per_second":  214.0,  "cpu_percentage":  27.71 },
  { "concurrency":   4, "requests_per_second":  295.48, "cpu_percentage":  32.38 },
  { "concurrency":   5, "requests_per_second":  350.77, "cpu_percentage":  44.17 },
  { "concurrency":  10, "requests_per_second":  670.44, "cpu_percentage":  48.18 },
  { "concurrency":  20, "requests_per_second": 1200.48, "cpu_percentage":  70.7  },
  { "concurrency":  40, "requests_per_second": 1791.86, "cpu_percentage":  85.16 },
  { "concurrency":  60, "requests_per_second": 1843.72, "cpu_percentage":  72.87 },
  { "concurrency":  80, "requests_per_second": 2015.35, "cpu_percentage":  86.41 },
  { "concurrency": 100, "requests_per_second": 2053.16, "cpu_percentage": 113.48 },
  { "concurrency": 120, "requests_per_second": 1761.43, "cpu_percentage":  90.06 },
  { "concurrency": 140, "requests_per_second": 2038.64, "cpu_percentage": 106.95 },
  { "concurrency": 160, "requests_per_second": 1700.96, "cpu_percentage":  92.28 },
  { "concurrency": 180, "requests_per_second": 1189.59, "cpu_percentage":  77.73 },
  { "concurrency": 200, "requests_per_second": 1603.21, "cpu_percentage":  77.16 }
]
```

<div id="jruby_short"></div>

#### Medium Response

```
$ ./typhoeus-test.rb GET http://medium-response.example.com  # 13801 bytes
[
  { "concurrency":   1, "requests_per_second":   59.98, "cpu_percentage":  12.8  },
  { "concurrency":   2, "requests_per_second":   87.71, "cpu_percentage":  14.39 },
  { "concurrency":   3, "requests_per_second":  147.43, "cpu_percentage":  24.2  },
  { "concurrency":   4, "requests_per_second":  198.15, "cpu_percentage":  27.6  },
  { "concurrency":   5, "requests_per_second":  238.36, "cpu_percentage":  33.47 },
  { "concurrency":  10, "requests_per_second":  418.5,  "cpu_percentage":  56.02 },
  { "concurrency":  20, "requests_per_second":  408.1,  "cpu_percentage":  47.92 },
  { "concurrency":  40, "requests_per_second":  405.78, "cpu_percentage":  47.66 },
  { "concurrency":  60, "requests_per_second":  407.69, "cpu_percentage":  49.13 },
  { "concurrency":  80, "requests_per_second":  428.75, "cpu_percentage":  63.96 },
  { "concurrency": 100, "requests_per_second":  427.38, "cpu_percentage":  66.76 },
  { "concurrency": 120, "requests_per_second":  317.95, "cpu_percentage":  45.96 },
  { "concurrency": 140, "requests_per_second":  378.5,  "cpu_percentage":  58.76 },
  { "concurrency": 160, "requests_per_second":  322.07, "cpu_percentage":  54.14 },
  { "concurrency": 180, "requests_per_second":  388.01, "cpu_percentage":  63.38 },
  { "concurrency": 200, "requests_per_second":  358.77, "cpu_percentage":  60.35 }
]
```

<div id="jruby_medium"></div>

## Results Discussion

In MRI Ruby, performance peaked at concurrency=80 for requests with very
small responses, and concurrency=20 for requests returning medium-sized
responses.  This represents a 24.5x and 8.5x speedup, respectively.
CPU consumption increases until around concurrency=60, at
which point it levels off.

In JRuby, concurrency=100 performed very well on both small and medium
responses, respectively offering 27x and 7x speedups compared to
concurrency=1.  CPU consumption peaked at concurrency=100 as well.

## Conclusions

It's clear from the results that Typhoeus goes a great job of bringing
HTTP request concurrency to both MRI Ruby and JRuby.  Leaning on libcurl
as it does allows for a clean, single-threaded framework around making
parallel HTTP calls.

Though the exact metric differs by platform and by response/request
characteristics (read: YMMV), the results show that
a concurrency between 40 and 60 is a good starting point for an
arbitrary-sized response.  From there, manual tuning (maybe even with
[this test script](typhoeus-test.rb)) can be used to arrive at optimal
performance for your use case.

Thanks to the authors of Typhoeus for making a great tool:
[David Balatero](https://github.com/dbalatero/),
[Paul Dix](https://github.com/pauldix), and
[Hans Hasselberg](https://github.com/i0rek).  Cheers!

## Authorship and License

This code and description were written by
[Pete Gamache](https://github.com/gamache),
and are released under the
[MIT License](MIT-LICENSE.txt).


<script src="http://d3js.org/d3.v3.min.js"></script>
<script src="http://dimplejs.org/dist/dimple.v2.1.2.min.js"></script>
<script type="text/javascript"> 
  var data = {
    'mri_short': [
      { "concurrency":   1, "requests_per_second":   68.98, "cpu_percentage":   7.4  },
      { "concurrency":   2, "requests_per_second":   93.2,  "cpu_percentage":   8.37 },
      { "concurrency":   3, "requests_per_second":  161.13, "cpu_percentage":  12.59 },
      { "concurrency":   4, "requests_per_second":  233.41, "cpu_percentage":  17.0  },
      { "concurrency":   5, "requests_per_second":  304.86, "cpu_percentage":  20.7  },
      { "concurrency":  10, "requests_per_second":  624.21, "cpu_percentage":  34.81 },
      { "concurrency":  20, "requests_per_second": 1108.17, "cpu_percentage":  50.85 },
      { "concurrency":  40, "requests_per_second": 1377.56, "cpu_percentage":  56.48 },
      { "concurrency":  60, "requests_per_second": 1489.14, "cpu_percentage":  56.43 },
      { "concurrency":  80, "requests_per_second": 1690.68, "cpu_percentage":  66.13 },
      { "concurrency": 100, "requests_per_second": 1493.8,  "cpu_percentage":  57.35 },
      { "concurrency": 120, "requests_per_second": 1597.41, "cpu_percentage":  64.18 },
      { "concurrency": 140, "requests_per_second": 1584.74, "cpu_percentage":  61.88 },
      { "concurrency": 160, "requests_per_second": 1422.99, "cpu_percentage":  59.42 },
      { "concurrency": 180, "requests_per_second": 1269.99, "cpu_percentage":  59.23 },
      { "concurrency": 200, "requests_per_second": 1331.68, "cpu_percentage":  62.02 }
    ],
    'mri_medium': [
      { "concurrency":   1, "requests_per_second":   60.92, "cpu_percentage":   8.79 },
      { "concurrency":   2, "requests_per_second":   89.51, "cpu_percentage":  11.62 },
      { "concurrency":   3, "requests_per_second":  160.21, "cpu_percentage":  19.11 },
      { "concurrency":   4, "requests_per_second":  206.05, "cpu_percentage":  24.36 },
      { "concurrency":   5, "requests_per_second":  254.53, "cpu_percentage":  28.07 },
      { "concurrency":  10, "requests_per_second":  471.2,  "cpu_percentage":  40.74 },
      { "concurrency":  20, "requests_per_second":  519.54, "cpu_percentage":  45.48 },
      { "concurrency":  40, "requests_per_second":  465.34, "cpu_percentage":  43.74 },
      { "concurrency":  60, "requests_per_second":  481.42, "cpu_percentage":  49.69 },
      { "concurrency":  80, "requests_per_second":  409.81, "cpu_percentage":  44.3  },
      { "concurrency": 100, "requests_per_second":  386.23, "cpu_percentage":  45.72 },
      { "concurrency": 120, "requests_per_second":  380.23, "cpu_percentage":  47.3  },
      { "concurrency": 140, "requests_per_second":  399.55, "cpu_percentage":  50.55 },
      { "concurrency": 160, "requests_per_second":  358.66, "cpu_percentage":  49.35 },
      { "concurrency": 180, "requests_per_second":  378.54, "cpu_percentage":  54.54 },
      { "concurrency": 200, "requests_per_second":  378.81, "cpu_percentage":  54.78 }
    ],
    'jruby_short': [
      { "concurrency":   1, "requests_per_second":   75.7,  "cpu_percentage":  17.39 },
      { "concurrency":   2, "requests_per_second":  134.47, "cpu_percentage":  19.43 },
      { "concurrency":   3, "requests_per_second":  214.0,  "cpu_percentage":  27.71 },
      { "concurrency":   4, "requests_per_second":  295.48, "cpu_percentage":  32.38 },
      { "concurrency":   5, "requests_per_second":  350.77, "cpu_percentage":  44.17 },
      { "concurrency":  10, "requests_per_second":  670.44, "cpu_percentage":  48.18 },
      { "concurrency":  20, "requests_per_second": 1200.48, "cpu_percentage":  70.7  },
      { "concurrency":  40, "requests_per_second": 1791.86, "cpu_percentage":  85.16 },
      { "concurrency":  60, "requests_per_second": 1843.72, "cpu_percentage":  72.87 },
      { "concurrency":  80, "requests_per_second": 2015.35, "cpu_percentage":  86.41 },
      { "concurrency": 100, "requests_per_second": 2053.16, "cpu_percentage": 113.48 },
      { "concurrency": 120, "requests_per_second": 1761.43, "cpu_percentage":  90.06 },
      { "concurrency": 140, "requests_per_second": 2038.64, "cpu_percentage": 106.95 },
      { "concurrency": 160, "requests_per_second": 1700.96, "cpu_percentage":  92.28 },
      { "concurrency": 180, "requests_per_second": 1189.59, "cpu_percentage":  77.73 },
      { "concurrency": 200, "requests_per_second": 1603.21, "cpu_percentage":  77.16 }
    ],
    'jruby_medium': [
      { "concurrency":   1, "requests_per_second":   59.98, "cpu_percentage":  12.8  },
      { "concurrency":   2, "requests_per_second":   87.71, "cpu_percentage":  14.39 },
      { "concurrency":   3, "requests_per_second":  147.43, "cpu_percentage":  24.2  },
      { "concurrency":   4, "requests_per_second":  198.15, "cpu_percentage":  27.6  },
      { "concurrency":   5, "requests_per_second":  238.36, "cpu_percentage":  33.47 },
      { "concurrency":  10, "requests_per_second":  418.5,  "cpu_percentage":  56.02 },
      { "concurrency":  20, "requests_per_second":  408.1,  "cpu_percentage":  47.92 },
      { "concurrency":  40, "requests_per_second":  405.78, "cpu_percentage":  47.66 },
      { "concurrency":  60, "requests_per_second":  407.69, "cpu_percentage":  49.13 },
      { "concurrency":  80, "requests_per_second":  428.75, "cpu_percentage":  63.96 },
      { "concurrency": 100, "requests_per_second":  427.38, "cpu_percentage":  66.76 },
      { "concurrency": 120, "requests_per_second":  317.95, "cpu_percentage":  45.96 },
      { "concurrency": 140, "requests_per_second":  378.5,  "cpu_percentage":  58.76 },
      { "concurrency": 160, "requests_per_second":  322.07, "cpu_percentage":  54.14 },
      { "concurrency": 180, "requests_per_second":  388.01, "cpu_percentage":  63.38 },
      { "concurrency": 200, "requests_per_second":  358.77, "cpu_percentage":  60.35 }
    ]
  };

  function plot(k) {
	 var svg = dimple.newSvg("#"+k, 750, 200);
	 var chart = new dimple.chart(svg, data[k]);
	 var x = chart.addCategoryAxis("x", "concurrency");
	 var y1 = chart.addMeasureAxis("y", "requests_per_second");
	 chart.addSeries(null, dimple.plot.line, [x, y1]);
	 var y2 = chart.addMeasureAxis("y", "cpu_percentage");
	 chart.addSeries(null, dimple.plot.scatter, [x, y2]);
	 chart.draw();
  }
  
  for (var k in data) plot(k);
</script>


