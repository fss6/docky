class GroupMembershipsController < ApplicationController
  before_action :set_group
  before_action :authorize_group

  def create
    @membership = @group.group_memberships.build(membership_params)

    if @membership.save
      redirect_to group_path(@group), notice: "Usuário adicionado ao grupo."
    else
      redirect_to group_path(@group), alert: @membership.errors.full_messages.to_sentence
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

  def membership_params
    params.expect(group_membership: [:user_id])
  end
end
