# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{candy_wrapper}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["palmade"]
  s.date = %q{2010-10-10}
  s.description = %q{Popular web API wrappers}
  s.email = %q{}
  s.extra_rdoc_files = ["LICENSE", "README", "lib/palmade/candy_wrapper.rb", "lib/palmade/candy_wrapper/bitlee.rb", "lib/palmade/candy_wrapper/http_fail.rb", "lib/palmade/candy_wrapper/mixins.rb", "lib/palmade/candy_wrapper/mixins/common_facilities.rb", "lib/palmade/candy_wrapper/pingers.rb", "lib/palmade/candy_wrapper/posporo.rb", "lib/palmade/candy_wrapper/twitow.rb"]
  s.files = ["CHANGELOG", "LICENSE", "Manifest", "README", "Rakefile", "lib/palmade/candy_wrapper.rb", "lib/palmade/candy_wrapper/bitlee.rb", "lib/palmade/candy_wrapper/http_fail.rb", "lib/palmade/candy_wrapper/mixins.rb", "lib/palmade/candy_wrapper/mixins/common_facilities.rb", "lib/palmade/candy_wrapper/pingers.rb", "lib/palmade/candy_wrapper/posporo.rb", "lib/palmade/candy_wrapper/twitow.rb", "candy_wrapper.gemspec"]
  s.homepage = %q{}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Candy_wrapper", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{palmade}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Popular web API wrappers}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
