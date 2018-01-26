FROM ruby:2.3

RUN apt-get update
RUN gem install bundler

RUN apt-get -y install lsof libav-tools
RUN curl https://www.stereotool.com/download/stereo_tool_cmd_64 > /usr/bin/stereo_tool_cmd
RUN chmod +x /usr/bin/stereo_tool_cmd

RUN mkdir /opt/sinatra
COPY Gemfile Gemfile.lock /opt/sinatra/

WORKDIR /opt/sinatra

RUN bundle install

COPY . /opt/sinatra/

CMD ["bundle", "exec", "rainbows", "-o", "0.0.0.0", "-p", "8080", "-c", "config.ra", "-w", "-d"]
