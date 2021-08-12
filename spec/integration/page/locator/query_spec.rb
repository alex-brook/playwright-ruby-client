require 'spec_helper'

RSpec.describe 'Locator' do
  it 'should respect first() and last()' do
    with_page do |page|
      page.content = <<~HTML
      <section>
        <div><p>A</p></div>
        <div><p>A</p><p>A</p></div>
        <div><p>A</p><p>A</p><p>A</p></div>
      </section>
      HTML

      expect(page.locator('div >> p').count).to eq(6)
      expect(page.locator('div').locator('p').count).to eq(6)
      expect(page.locator('div').first.locator('p').count).to eq(1)
      expect(page.locator('div').last.locator('p').count).to eq(3)
    end
  end

  it 'should respect nth()' do
    with_page do |page|
      page.content = <<~HTML
      <section>
        <div><p>A</p></div>
        <div><p>A</p><p>A</p></div>
        <div><p>A</p><p>A</p><p>A</p></div>
      </section>
      HTML

      expect(page.locator('div >> p').nth(0).count).to eq(1)
      expect(page.locator('div').nth(1).locator('p').count).to eq(2)
      expect(page.locator('div').nth(2).locator('p').count).to eq(3)
    end
  end

  it 'should throw on capture w/ nth()' do
    with_page do |page|
      page.content = '<section><div><p>A</p></div></section>'
      expect { page.locator('*css=div >> p').nth(1).click }.to raise_error(/Can't query n-th element/)
    end
  end

  it 'should throw on due to strictness' do
    with_page do |page|
      page.content = '<div>A</div><div>B</div>'
      expect { page.locator('div').visible? }.to raise_error(/strict mode violation/)
    end
  end

  it 'should throw on due to strictness' do
    with_page do |page|
      page.content = '<select><option>One</option><option>Two</option></select>'
      expect { page.locator('option').evaluate('e => {}') }.to raise_error(/strict mode violation/)
    end
  end
end
