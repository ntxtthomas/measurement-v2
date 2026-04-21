require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:user)     { create(:user) }
  let(:org)      { create(:organization) }
  let!(:observer) { create(:observer, user: user, organization: org) }

  def sign_in
    post login_path, params: { email: user.email, password: "password" }
  end

  describe "GET /" do
    it "redirects to login when not authenticated" do
      get root_path
      expect(response).to redirect_to(login_path)
    end

    it "renders 200 when authenticated" do
      sign_in
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the organization stats table" do
      sign_in
      get root_path
      expect(response.body).to include(org.name)
    end

    # NOTE: N+1 regression test placeholder.
    # After fixing DashboardController to use eager loading, add a query count
    # assertion here using db-query-matchers or a custom counter.
    #
    # Example (after fix):
    #   it "does not make N+1 queries for org stats" do
    #     create_list(:school, 3, organization: org)
    #     sign_in
    #     expect { get root_path }.to make_database_queries(count: 1..10)
    #   end
  end
end
