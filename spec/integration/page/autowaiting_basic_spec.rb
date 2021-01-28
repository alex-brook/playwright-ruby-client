require 'spec_helper'

RSpec.describe 'autowaiting basic' do
  let(:endpoint) { "/empty_#{SecureRandom.hex(24)}" }
  it 'should await navigation when clicking anchor', sinatra: true do
    messages = []

    sinatra.get(endpoint) do
      messages << 'route'
      headers('Content-Type' => 'text/html')
      body("<link rel='stylesheet' href='./one-style.css'>")
    end

    with_page do |page|
      page.content = "<a href=\"#{server_prefix}#{endpoint}\" >empty.html</a>"

      promises = [
        Concurrent::Promises.future {
          sleep 0.5
          page.click('a')
          messages << 'click'
        },
        Concurrent::Promises.future {
          page.wait_for_event('framenavigated')
          messages << 'navigated'
        }
      ]
      Concurrent::Promises.zip(*promises).value!
    end

    expect(messages).to eq(%w(route navigated click))
  end

  it 'should await cross-process navigation when clicking anchor', sinatra: true do
    messages = []

    sinatra.get(endpoint) do
      messages << 'route'
      headers('Content-Type' => 'text/html')
      body("<link rel='stylesheet' href='./one-style.css'>")
    end

    with_page do |page|
      page.content = "<a href=\"#{server_cross_process_prefix}#{endpoint}\" >empty.html</a>"

      promises = [
        Concurrent::Promises.future {
          sleep 0.5
          page.click('a')
          messages << 'click'
        },
        Concurrent::Promises.future {
          page.wait_for_event('framenavigated')
          messages << 'navigated'
        }
      ]
      Concurrent::Promises.zip(*promises).value!
    end

    expect(messages).to eq(%w(route navigated click))
  end

  it 'should await form-get on click', sinatra: true do
    messages = []

    sinatra.get(endpoint) do
      messages << 'route'
      headers('Content-Type' => 'text/html')
      body("<link rel='stylesheet' href='./one-style.css'>")
    end

    with_page do |page|
      html = <<~HTML
      <form action="#{server_cross_process_prefix}#{endpoint}" method="get">
        <input name="foo" value="bar">
        <input type="submit" value="Submit">
      </form>
      HTML
      page.content = html

      promises = [
        Concurrent::Promises.future {
          sleep 0.5
          page.click('input[type=submit]')
          messages << 'click'
        },
        Concurrent::Promises.future {
          page.wait_for_event('framenavigated')
          messages << 'navigated'
        }
      ]
      Concurrent::Promises.zip(*promises).value!
    end

    expect(messages).to eq(%w(route navigated click))
  end

  it 'should await form-post on click', sinatra: true do
    messages = []

    sinatra.post(endpoint) do
      messages << 'route'
      headers('Content-Type' => 'text/html')
      body("<link rel='stylesheet' href='./one-style.css'>")
    end

    with_page do |page|
      html = <<~HTML
      <form action="#{server_cross_process_prefix}#{endpoint}" method="post">
        <input name="foo" value="bar">
        <input type="submit" value="Submit">
      </form>
      HTML
      page.content = html

      promises = [
        Concurrent::Promises.future {
          sleep 0.5
          page.click('input[type=submit]')
          messages << 'click'
        },
        Concurrent::Promises.future {
          page.wait_for_event('framenavigated')
          messages << 'navigated'
        }
      ]
      Concurrent::Promises.zip(*promises).value!
    end

    expect(messages).to eq(%w(route navigated click))
  end

  it 'should await navigation when assigning location', sinatra: true do
    messages = []

    sinatra.get(endpoint) do
      messages << 'route'
      headers('Content-Type' => 'text/html')
      body("<link rel='stylesheet' href='./one-style.css'>")
    end

    with_page do |page|
      promises = [
        Concurrent::Promises.future {
          sleep 0.5
          page.evaluate("window.location.href = \"#{server_cross_process_prefix}#{endpoint}\"")
          messages << 'evaluate'
        },
        Concurrent::Promises.future {
          page.wait_for_event('framenavigated')
          messages << 'navigated'
        }
      ]
      Concurrent::Promises.zip(*promises).value!
    end

    expect(messages).to eq(%w(route navigated evaluate))
  end

  it 'should await navigation when assigning location twice', sinatra: true do
    messages = []

    sinatra.get("#{endpoint}/cancel") { 'done' }
    sinatra.get("#{endpoint}/override") { messages << 'routeoverride' ; 'done' }

    with_page do |page|
      js = <<~JAVASCRIPT
      window.location.href = "#{server_cross_process_prefix}#{endpoint}/cancel";
      window.location.href = "#{server_cross_process_prefix}#{endpoint}/override";
      JAVASCRIPT

      page.evaluate(js)
      messages << 'evaluate'
    end

    expect(messages).to eq(%w(routeoverride evaluate))
  end

  it 'should await navigation when evaluating reload', sinatra: true do
    messages = []

    sinatra.get(endpoint) do
      messages << 'route'
      headers('Content-Type' => 'text/html')
      body("<link rel='stylesheet' href='./one-style.css'>")
    end

    with_page do |page|
      page.goto("#{server_prefix}#{endpoint}")
      messages.clear

      promises = [
        Concurrent::Promises.future {
          sleep 0.5
          page.evaluate('window.location.reload()')
          messages << 'evaluate'
        },
        Concurrent::Promises.future {
          page.wait_for_event('framenavigated')
          messages << 'navigated'
        }
      ]
      Concurrent::Promises.zip(*promises).value!
    end

    expect(messages).to eq(%w(route navigated evaluate))
  end

  it 'should await navigating specified target', sinatra: true do
    messages = []

    sinatra.get(endpoint) do
      messages << 'route'
      headers('Content-Type' => 'text/html')
      body("<link rel='stylesheet' href='./one-style.css'>")
    end

    with_page do |page|
      html = <<~HTML
      <a href="#{server_prefix}#{endpoint}" target=target>empty.html</a>
      <iframe name=target></iframe>
      HTML
      page.content = html

      frame = page.frame({name: 'target'})
      promises = [
        Concurrent::Promises.future {
          sleep 0.5
          page.click('a')
          messages << 'click'
        },
        Concurrent::Promises.future {
          page.wait_for_event('framenavigated')
          messages << 'navigated'
        }
      ]
      Concurrent::Promises.zip(*promises).value!
      expect(frame.url).to eq("#{server_prefix}#{endpoint}")
    end

    expect(messages).to eq(%w(route navigated click))
  end

  it 'should work with noWaitAfter: true', sinatra: true do
    sinatra.get(endpoint) { sleep 30 }

    with_page do |page|
      page.content = "<a href=\"#{server_prefix}#{endpoint}\" >empty.html</a>"

      Timeout.timeout(3) do
        page.click('a', noWaitAfter: true)
      end
    end
  end

  it 'should work with dblclick noWaitAfter: true', sinatra: true do
    sinatra.get(endpoint) { sleep 30 }

    with_page do |page|
      page.content = "<a href=\"#{server_prefix}#{endpoint}\" >empty.html</a>"

      Timeout.timeout(3) do
        page.dblclick('a', noWaitAfter: true)
      end
    end
  end

  it 'should work with waitForLoadState(load)', sinatra: true do
    messages = []

    sinatra.get(endpoint) do
      messages << 'route'
      headers('Content-Type' => 'text/html')
      body("<link rel='stylesheet' href='./one-style.css'>")
    end

    with_page do |page|
      page.content = "<a href=\"#{server_prefix}#{endpoint}\" >empty.html</a>"

      promises = [
        Concurrent::Promises.future {
          sleep 0.5
          page.click('a')
          page.wait_for_load_state(state: 'load')
          messages << 'clickload'
        },
        Concurrent::Promises.future {
          page.wait_for_event('framenavigated')
          page.wait_for_load_state(state: 'domcontentloaded')
          messages << 'domcontentloaded'
        }
      ]
      Concurrent::Promises.zip(*promises).value!
    end
    expect(messages).to eq(%w(route domcontentloaded clickload))
  end

  it 'should work with goto following click', sinatra: true do
    sinatra.get('/login.html') do
      headers('Content-Type' => 'text/html')
      body('You are logged in')
    end

    with_page do |page|
      html = <<~HTML
      <form action="#{server_prefix}/login.html" method="get">
        <input type="text">
        <input type="submit" value="Submit">
      </form>
      HTML
      page.content = html

      page.fill('input[type="text"]', 'admin')
      page.click('input[type="submit"]')
      page.goto(server_empty_page)
    end
  end

  # it('should report navigation in the log when clicking anchor', (test, { mode }) => {
  #   test.skip(mode !== 'default');
  # }, async ({page, server}) => {
  #   await page.setContent(`<a href="${server.PREFIX + '/frames/one-frame.html'}">click me</a>`);
  #   const __testHookAfterPointerAction = () => new Promise(f => setTimeout(f, 6000));
  #   const error = await page.click('a', { timeout: 5000, __testHookAfterPointerAction } as any).catch(e => e);
  #   expect(error.message).toContain('page.click: Timeout 5000ms exceeded.');
  #   expect(error.message).toContain('waiting for scheduled navigations to finish');
  #   expect(error.message).toContain(`navigated to "${server.PREFIX + '/frames/one-frame.html'}"`);
  # });
end