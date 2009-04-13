Then /^that email should contain a link to edit the latest testimonial$/ do
  testimonial = Testimonial.last
  @email.message.should =~ /#{edit_testimonial_url(testimonial)}/m
end

When /^I visit the edit page for the latest testimonial$/ do
  testimonial = Testimonial.last
  visit edit_testimonial_path(testimonial)
end
