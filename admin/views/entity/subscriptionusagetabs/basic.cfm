<cfimport prefix="swa" taglib="../../../../tags" />
<cfimport prefix="hb" taglib="../../../../org/Hibachi/HibachiTags" />

<cfparam name="rc.subscriptionUsage" type="any">
<cfparam name="rc.edit" type="boolean">

<cfoutput>
	<hb:HibachiEntityDetailForm object="#rc.subscriptionUsage#" edit="#rc.edit#" saveActionQueryString="subscriptionUsageID=#rc.subscriptionUsage.getSubscriptionUsageID()#">
		<hb:HibachiEntityActionBar type="detail" object="#rc.subscriptionUsage#">
			<hb:HibachiProcessCaller entity="#rc.subscriptionUsage#" action="admin:entity.preProcessSubscriptionUsage" processContext="renew" type="list" modal="true" />
			<hb:HibachiProcessCaller entity="#rc.subscriptionUsage#" action="admin:entity.preProcessSubscriptionUsage" processContext="cancel" type="list" modal="true" />
			<hb:HibachiProcessCaller entity="#rc.subscriptionUsage#" action="admin:entity.processSubscriptionUsage" processContext="updateStatus" type="list" />
			<hb:HibachiProcessCaller entity="#rc.subscriptionUsage#" action="admin:entity.processSubscriptionUsage" processContext="sendRenewalReminder" type="list" />
			<hb:HibachiProcessCaller entity="#rc.subscriptionUsage#" action="admin:entity.preprocesssubscriptionusage" processContext="addUsageBenefit" type="list" modal="true" />
		</hb:HibachiEntityActionBar>
		
		<hb:HibachiPropertyRow>
			<hb:HibachiPropertyList divClass="col-md-6">
				<hb:HibachiPropertyDisplay object="#rc.subscriptionUsage#" property="currentStatusType" edit="false">
				<hb:HibachiPropertyDisplay object="#rc.subscriptionUsage#" property="autoRenewFlag" edit="#rc.edit#">
				<hb:HibachiPropertyDisplay object="#rc.subscriptionUsage#" property="autoPayFlag" edit="#rc.edit#">
				<hb:HibachiPropertyDisplay object="#rc.subscriptionUsage#" property="renewalPrice" edit="#rc.edit#">
				<hb:HibachiPropertyDisplay object="#rc.subscriptionUsage#" property="accountPaymentMethod" edit="#rc.edit#">
			</hb:HibachiPropertyList>
			<hb:HibachiPropertyList divClass="col-md-6">
				<hb:HibachiPropertyDisplay object="#rc.subscriptionUsage#" property="expirationDate" edit="#rc.edit#">
				<hb:HibachiPropertyDisplay object="#rc.subscriptionUsage#" property="gracePeriodTerm" edit="#rc.edit#">
				<hb:HibachiPropertyDisplay object="#rc.subscriptionUsage#" property="nextBillDate" edit="#rc.edit#">
				<hb:HibachiPropertyDisplay object="#rc.subscriptionUsage#" property="nextReminderEmailDate" edit="#rc.edit#">
			</hb:HibachiPropertyList>
		</hb:HibachiPropertyRow>

	</hb:HibachiEntityDetailForm>
</cfoutput>

