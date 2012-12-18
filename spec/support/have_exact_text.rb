module Capybara::Node::Matchers
  def has_exact_text?(content)
    synchronize do
      unless text == content
        raise Capybara::ExpectationNotMet
      end                                                                                   
    end
    return true
  rescue Capybara::ExpectationNotMet                                                        
    return false                                                                            
  end 

  alias_method :has_exact_content?, :has_exact_text?

  def does_not_have_exact_text?(content)
    synchronize do
      if text == content
        raise Capybara::ExpectationNotMet
      end                                                                                   
    end
    return true
  rescue Capybara::ExpectationNotMet                                                        
    return false                                                                            
  end 

  alias_method :does_not_have_exact_content?, :does_not_have_exact_text?
end

module Capybara::RSpecMatchers
  class HaveExactText
    attr_reader :text

    def initialize(text)
      @text = text
    end

    def matches?(actual)
      @actual = wrap(actual)
      @actual.has_exact_text?(text)
    end

    def does_not_match?(actual)
      @actual = wrap(actual)
      @actual.does_not_have_exact_text?(text)
    end

    def failure_message_for_should
      "expected #{format(text)} to equal #{format(@actual.text)}"
    end

    def failure_message_for_should_not
      "expected #{format(text)} to not equal #{format(@actual.text)}"
    end

    def description
      "equal #{format(text)}"
    end

    def wrap(actual)
      if actual.respond_to?("has_selector?")
        actual
      else
        Capybara.string(actual.to_s)
      end
    end

    def format(text)
      text = Capybara::Helpers.normalize_whitespace(text) unless text.is_a? Regexp
      text.inspect
    end
  end

  def have_exact_content(text)
    HaveExactText.new(text)
  end

  def have_exact_text(text)
    HaveExactText.new(text)
  end

  def does_not_have_exact_content(text)
    HaveExactText.new(text)
  end

  def does_not_have_exact_text(text)
    HaveExactText.new(text)
  end
end

