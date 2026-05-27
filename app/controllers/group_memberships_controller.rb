class GroupMembershipsController < ApplicationController
  before_action :set_group
  before_action :authorize_group

  def create
    @membership = @group.group_memberships.build(membership_params)

    if @membership.save
      redirect_to group_path(@group), notice: "Usuário adicionado ao grupo."
    else
      load_group_show_context
      render "groups/show", status: :unprocessable_entity
    end
  end

  def destroy
    @membership = @group.group_memberships.find(params.expect(:id))
    @membership.destroy!
    redirect_to group_path(@group), notice: "Usuário removido do grupo.", status: :see_other
  end

  private

  def authorize_group
    authorize @group, :update?
  end

  def set_group
    @group = Group.includes(:account).find(params.expect(:group_id))
  end

  def load_group_show_context
    @memberships = @group.group_memberships.joins(:user).includes(:user).order("users.name")
    member_ids = @group.user_ids
    @available_users =
      if member_ids.empty?
        @group.account.users.order(:name)
      else
        @group.account.users.where.not(id: member_ids).order(:name)
      end
  end

  def membership_params
    params.expect(group_membership: [:user_id])
  end
end
