# Slim test suite

You can run this testsuite with `rake test:literate`.

We use pretty mode in the test suite to make the output more readable. Pretty mode
is enabled by setting the option

~~~ options
:pretty => true
~~~

## Line indicators

In this section we test all line indicators.

### HTML comment `/!`

Code comments begin with `/!`.

~~~ slim
/! Comment
body
  /! Another comment
     with multiple lines
  p Hello!
  /!
      First line determines indentation

      of the comment
~~~

renders as

~~~ html
<!--Comment-->
<body>
  <!--Another comment
  with multiple lines-->
  <p>Hello!</p>
  <!--First line determines indentation
  
  of the comment-->
</body>
~~~



## Embedded engines

## Configuring Slim

## Plugins

### Logic less mode

### Translator
