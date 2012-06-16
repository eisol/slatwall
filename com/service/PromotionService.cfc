/*

    Slatwall - An Open Source eCommerce Platform
    Copyright (C) 2011 ten24, LLC

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    Linking this library statically or dynamically with other modules is
    making a combined work based on this library.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.
 
    As a special exception, the copyright holders of this library give you
    permission to link this library with independent modules to produce an
    executable, regardless of the license terms of these independent
    modules, and to copy and distribute the resulting executable under
    terms of your choice, provided that you also meet, for each linked
    independent module, the terms and conditions of the license of that
    module.  An independent module is a module which is not derived from
    or based on this library.  If you modify this library, you may extend
    this exception to your version of the library, but you are not
    obligated to do so.  If you do not wish to do so, delete this
    exception statement from your version.

Notes:

*/
component extends="Slatwall.com.service.BaseService" persistent="false" accessors="true" output="false" {

	property name="roundingRuleService" type="any";
	property name="utilityService" type="any";

		
	// ----------------- START: Apply Promotion Logic ------------------------- 
	public void function updateOrderAmountsWithPromotions(required any order) {
		
		// Sale & Exchange Orders
		if( listFindNoCase("otSalesOrder,otExchangeOrder", arguments.order.getOrderType().getSystemCode()) ) {
			
			// Clear all previously applied promotions for order items
			for(var oi=1; oi<=arrayLen(arguments.order.getOrderItems()); oi++) {
				for(var pa=arrayLen(arguments.order.getOrderItems()[oi].getAppliedPromotions()); pa >= 1; pa--) {
					arguments.order.getOrderItems()[oi].getAppliedPromotions()[pa].removeOrderItem();
				}
			}
			
			// Clear all previously applied promotions for fulfillment
			for(var of=1; of<=arrayLen(arguments.order.getOrderFulfillments()); of++) {
				for(var pa=arrayLen(arguments.order.getAppliedPromotions()); pa >= 1; pa--) {
					arguments.order.getAppliedPromotions()[pa].removeOrderFulfillment();
				}
			}
			
			// Clear all previously applied promotions for order
			for(var pa=arrayLen(arguments.order.getAppliedPromotions()); pa >= 1; pa--) {
				arguments.order.getAppliedPromotions()[pa].removeOrder();
			}
			
			// Loop over orderItems and apply Sale Prices
			for(var oi=1; oi<=arrayLen(arguments.order.getOrderItems()); oi++) {
				var orderItem = arguments.order.getOrderItems()[oi];
				var salePriceDetails = orderItem.getSku().getSalePriceDetails();

				if(structKeyExists(salePriceDetails, "salePrice") && salePriceDetails.salePrice < orderItem.getSku().getPrice()) {
					var discountAmount = precisionEvaluate((orderItem.getSku().getPrice() * orderItem.getQuantity()) - (salePriceDetails.salePrice * orderItem.getQuantity()));

					var newAppliedPromotion = this.newPromotionApplied();
					newAppliedPromotion.setAppliedType('orderItem');
					newAppliedPromotion.setPromotion( this.getPromotion(salePriceDetails.promotionID) );
					newAppliedPromotion.setOrderItem( orderItem );
					newAppliedPromotion.setDiscountAmount( discountAmount );
				}
			}
			
			
			var rewardUsageDetails = {};
			var orderItemAppliedRewards = {};
			
			// This is a structure of promotionPeriods that will get checked and cached as to if we are still within the period use count, and period account use count
			var promotionPeriodQualifications = {};
			
			/*
			promotionPeriodQualifications = {
				promotionPeriodID = {
					promotionPeriodQualifies = true | false,
					orderQulifies = true | false,
					qualifiedFulfillmentIDList = "comma seperated list of ID's"
				}
			};
			
			rewardUsageDetails = {
				promotionRewardID1 = {
					promotionReward = promotionRewardEntity,
					totalUseCount = 0,
					maximumUsePerOrder = 1000000,
					maximumUsePerItem = 1000000,
					maximumUsePerQualification = 1000000
				},
				promotionRewardID2 = {
					promotionReward = promotionRewardEntity,
					totalUseCount = 0,
					maximumUsePerOrder = 1000000,
					maximumUsePerItem = 1000000,
					maximumUsePerQualification = 1000000
				}
			};
			
			orderItemAppliedRewards = {
				orderItemID1 = {
					promotionRewardID = 0,
					useQuantity = 0,
					totalDiscountAmount = 0
				},
				orderItemID2 = {
					promotionRewardID = 0,
					useQuantity = 0,
					totalDiscountAmount = 0
				}
			};
			
			*/
			
			// Loop over all Potential Discounts that require qualifications
			var promotionRewards = getDAO().getActivePromotionRewards(rewardTypeList="merchandise,subscription,contentAccess,order,fulfillment", promotionCodeList=arguments.order.getPromotionCodeList(), qualificationRequired=true);
			for(var pr=1; pr<=arrayLen(promotionRewards); pr++) {
				
				var reward = promotionRewards[pr];
				
				// Setup the boolean for if the promotionPeriod is okToApply based on general use count
				if(!structKeyExists(promotionPeriodQualifications, reward.getPromotionPeriod().getPromotionPeriodID())) {
					promotionPeriodQualifications[ reward.getPromotionPeriod().getPromotionPeriodID() ] = {};
					promotionPeriodQualifications[ reward.getPromotionPeriod().getPromotionPeriodID() ].promotionPeriodQualifies = getPromotionPeriodOKToApply(promotionPeriod=reward.getPromotionPeriod(), order=arguments.order);
				}
				
				// If this promotion period is ok to apply based on general useCount
				if(promotionPeriodQualifications[ reward.getPromotionPeriod().getPromotionPeriodID() ].promotionPeriodQualifies) {
					
					// Now that we know the period is ok, lets check and cache if the order qualifiers
					if(!structKeyExists(promotionPeriodQualifications[reward.getPromotionPeriod().getPromotionPeriodID()], "orderQulifies")) {
						promotionPeriodQualifications[reward.getPromotionPeriod().getPromotionPeriodID()].orderQulifies = getPromotionPeriodOkToApplyByOrderQualifiers(promotionPeriod=reward.getPromotionPeriod(), order=arguments.order);
					}
					
					// If order qualifies for the rewards promotion period
					if(promotionPeriodQualifications[reward.getPromotionPeriod().getPromotionPeriodID()].orderQulifies) {
						
						// Now that we know the order is ok, lets check and cache if at least one of the fulfillment qualifies
						if(!structKeyExists(promotionPeriodQualifications[reward.getPromotionPeriod().getPromotionPeriodID()], "qualifiedFulfillmentIDList")) {
							promotionPeriodQualifications[reward.getPromotionPeriod().getPromotionPeriodID()].qualifiedFulfillmentIDList = getPromotionPeriodQualifiedFulfillmentIDList(promotionPeriod=reward.getPromotionPeriod(), order=arguments.order);
						}
						
						if(len(promotionPeriodQualifications[reward.getPromotionPeriod().getPromotionPeriodID()].qualifiedFulfillmentIDList)) {
							
							switch(reward.getRewardType()) {
								
								// =============== Order Item Reward ==============
								case "merchandise": case "subscription": case "contentAccess":
								
									// Loop over all the orderItems
									for(var i=1; i<=arrayLen(arguments.order.getOrderItems()); i++) {
										
										// Get The order Item
										var orderItem = arguments.order.getOrderItems()[i];
										
										// Verify that this is an item being sold
										if(orderItem.getOrderItemType().getSystemCode() == "oitSale") {
											
											// Make sure that this order item is in the acceptable fulfillment list
											if(listFindNoCase(promotionPeriodQualifications[reward.getPromotionPeriod().getPromotionPeriodID()].qualifiedFulfillmentIDList, orderItem.getOrderFulfillment().getOrderFulfillmentID())) {
											
												// Check the reward settings to see if this orderItem applies
												if( ( !arrayLen( reward.getProductTypes() ) || reward.hasProductType( orderItem.getSku().getProduct().getProductType() ) )
													&&
													( !arrayLen( reward.getProducts() ) || reward.hasProduct( orderItem.getSku().getProduct() ) )
													&&
													( !arrayLen( reward.getSkus() ) || reward.hasSku( orderItem.getSku() ) )
													&&
													( !arrayLen( reward.getBrands() ) || reward.hasBrand( orderItem.getSku().getProduct().getBrand() ) )
													&&
													( !arrayLen( reward.getOptions() ) || reward.hasAnyOption( orderItem.getSku().getOptions() ) )  	) {
													
													/*
													// If there is not applied Price Group, or if this reward has the applied pricegroup as an eligible one then use priceExtended... otherwise use skuPriceExtended and then adjust the discount.
													if( isNull(orderItem.getAppliedPriceGroup()) || reward.hasEligiblePriceGroup( orderItem.getAppliedPriceGroup() ) ) {
														// Calculate based on price, which could be a priceGroup price
														var discountAmount = getDiscountAmount(reward, orderItem.getExtendedPrice());
													} else {
														// Calculate based on skuPrice because the price on this item is a priceGroup price and we need to adjust the discount by the difference
														var originalDiscountAmount = getDiscountAmount(reward, orderItem.getExtendedSkuPrice());
														// Take the original discount they were going to get without a priceGroup and subtract the difference of the discount that they are already receiving
														var discountAmount = precisionEvaluate(originalDiscountAmount - (orderItem.getExtendedSkuPrice() - orderItem.getExtendedPrice()));
													}
													*/
													
													var addNew = false;
													var discountAmount = getDiscountAmount(reward, orderItem.getExtendedPrice());
													
													// First we make sure that the discountAmount is > 0 before we check if we should add more discount
													if(discountAmount > 0) {
														// If there aren't any promotions applied to this order item yet, then we can add this one
														if(!arrayLen(orderItem.getAppliedPromotions())) {
															addNew = true;
														// If one has already been set then we just need to check if this new discount amount is greater
														} else if ( orderItem.getAppliedPromotions()[1].getDiscountAmount() < discountAmount ) {
															
															// If the promotion is the same, then we just update the amount
															if(orderItem.getAppliedPromotions()[1].getPromotion().getPromotionID() == reward.getPromotionPeriod().getPromotion().getPromotionID()) {
																orderItem.getAppliedPromotions()[1].setDiscountAmount(discountAmount);
																
															// If the promotion is a different then remove the original and set addNew to true
															} else {
																orderItem.getAppliedPromotions()[1].removeOrderItem();
																addNew = true;
															}
															
														}
													}
													
													// Add the new appliedPromotion
													if(addNew) {
														var newAppliedPromotion = this.newPromotionApplied();
														newAppliedPromotion.setAppliedType('orderItem');
														newAppliedPromotion.setPromotion( reward.getPromotionPeriod().getPromotion() );
														newAppliedPromotion.setOrderItem( orderItem );
														newAppliedPromotion.setDiscountAmount( discountAmount );
													}
													
												} // End OrderItem in reward IF
												
											} // End orderItem fulfillment in qualifiedFulfillment list
												
										} // END Sale Item If
										
									} // End Order Item For Loop
												
									break;
									
								// =============== Fulfillment Reward ======================
								case "fulfillment":
								
									// Loop over all the fulfillments
									for(var of=1; of<=arrayLen(arguments.order.getOrderFulfillments()); of++) {
										
										// Get this order Fulfillment
										var orderFulfillment = arguments.order.getOrderFulfillments()[of];
										
										if( ( !arrayLen(reward.getFulfillmentMethods()) || reward.hasFulfillmentMethod(orderFulfillment.getFulfillmentMethod()) ) 
											&&
											( !arrayLen(reward.getShippingMethods()) || (!isNull(orderFulfillment.getShippingMethod()) && reward.hasShippingMethod(orderFulfillment.getShippingMethod()) ) ) ) {
											
											var discountAmount = getDiscountAmount(reward, orderFulfillment.getFulfillmentCharge());
											
											var addNew = false;
												
											// First we make sure that the discountAmount is > 0 before we check if we should add more discount
											if(discountAmount > 0) {
												
												// If there aren't any promotions applied to this order fulfillment yet, then we can add this one
												if(!arrayLen(orderFulfillment.getAppliedPromotions())) {
													addNew = true;
													
												// If one has already been set then we just need to check if this new discount amount is greater
												} else if ( orderFulfillment.getAppliedPromotions()[1].getDiscountAmount() < discountAmount ) {
													
													// If the promotion is the same, then we just update the amount
													if(orderFulfillment.getAppliedPromotions()[1].getPromotion().getPromotionID() == reward.getPromotionPeriod().getPromotion().getPromotionID()) {
														orderFulfillment.getAppliedPromotions()[1].setDiscountAmount(discountAmount);
														
													// If the promotion is a different then remove the original and set addNew to true
													} else {
														orderFulfillment.getAppliedPromotions()[1].removeOrderFulfillment();
														addNew = true;
													}
												}
											}
											
											// Add the new appliedPromotion
											if(addNew) {
												var newAppliedPromotion = this.newPromotionApplied();
												newAppliedPromotion.setAppliedType('orderFulfillment');
												newAppliedPromotion.setPromotion( reward.getPromotionPeriod().getPromotion() );
												newAppliedPromotion.setOrderFulfillment( orderFulfillment );
												newAppliedPromotion.setDiscountAmount( discountAmount );
											}
										}
									}
									
									break;
									
								// ================== Order Reward =========================
								case "order": 
								
									break;
							
							} // End rewardType Switch
							
						} // END Len of fulfillmentID list
					
					} // END Order Qualifies IF
				
				} // END Promotion Period OK IF
			
			} // END of PromotionReward Loop
			
		} // END of Sale or Exchange Loop
		
		// Return & Exchange Orders
		if( listFindNoCase("otReturnOrder,otExchangeOrder", arguments.order.getOrderType().getSystemCode()) ) {
			// TODO: In the future allow for return Items to have negative promotions applied.  This isn't import right now because you can determine how much you would like to refund ordersItems
		}

	}
	
	private boolean function getPromotionPeriodOKToApply(required any promotionPeriod, required any order) {
		if(!isNull(arguments.promotionPeriod.getMaximumUseCount()) && arguments.promotionPeriod.getMaximumUseCount() gt 0) {
			var periodUseCount = getDAO().getPromotionPeriodUseCount(promotionPeriod = arguments.promotionPeriod);	
			if(periodUseCount >= arguments.promotionPeriod.getMaximumUseCount()) {
				return false;
			} 
		}
		if(!isNull(arguments.promotionPeriod.getMaximumAccountUseCount()) && arguments.promotionPeriod.getMaximumAccountUseCount() gt 0) {
			var periodAccountUseCount = getDAO().getPromotionPeriodAccountUseCount(promotionPeriod = arguments.promotionPeriod, account=arguments.order.getAccount());
			if(periodAccountUseCount >= arguments.promotionPeriod.getMaximumAccountUseCount()) {
				return false;
			}
		}
		
		return true;
	}
	
	private boolean function getPromotionPeriodOkToApplyByOrderQualifiers(required any promotionPeriod, required any order) {
		// Loop over Qualifiers looking for order qualifiers
		for(var q=1; q<=arrayLen(arguments.promotionPeriod.getPromotionQualifiers()); q++) {
			
			var qualifier = arguments.promotionPeriod.getPromotionQualifiers()[q];
			
			if(qualifier.getQualifierType() == "order") {
				// Minimum Order Quantity
				if(!isNull(qualifier.getMinimumOrderQuantity()) && qualifier.getMinimumOrderQuantity() > arguments.order.getTotalSaleQuantity()) {
					return false;
				}
				// Maximum Order Quantity
				if(!isNull(qualifier.getMaximumOrderQuantity()) && qualifier.getMaximumOrderQuantity() < arguments.order.getTotalSaleQuantity()) {
					return false;
				}
				// Minimum Order Subtotal
				if(!isNull(qualifier.getMinimumOrderSubtotal()) && qualifier.getMinimumOrderSubtotal() > arguments.order.getSubtotal()) {
					return false;
				}
				// Maximum Order Substotal
				if(!isNull(qualifier.getMaximumOrderSubtotal()) && qualifier.getMaximumOrderSubtotal() < arguments.order.getSubtotal()) {
					return false;
				}
			}	
		}
		
		return true;
	}
	
	private string function getPromotionPeriodQualifiedFulfillmentIDList(required any promotionPeriod, required any order) {
		var qualifiedFulfillmentIDs = "";
		
		// Loop over Qualifiers looking for fulfillment qualifiers
		for(var q=1; q<=arrayLen(arguments.promotionPeriod.getPromotionQualifiers()); q++) {
			
			var qualifier = arguments.promotionPeriod.getPromotionQualifiers()[q];
			
			if(qualifier.getQualifierType() == "fulfillment") {
				
				// Loop over fulfillments to see if it qualifies, and if so add to the list
				for(var f=1; f<=arrayLen(arguments.order.getOrderFulfillments()); f++) {
					var orderFulfillment = arguments.order.getOrderFulfillments()[f];
					if( (isNull(qualifier.getMinimumFulfillmentWeight()) || qualifier.getMinimumFulfillmentWeight() < orderFulfillment.getTotalShippingWeight() ) && (isNull(qualifier.getMaximumFulfillmentWeight()) || qualifier.getMaximumFulfillmentWeight() > orderFulfillment.getTotalShippingWeight() )) {
						qualifiedFulfillmentIDs = listAppend(qualifiedFulfillmentIDs, orderFulfillment.getOrderFulfillmentID());
					}
				}
			}	
		}
		
		return qualifiedFulfillmentIDs;
	}
	
	
	private numeric function getDiscountAmount(required any reward, required any originalAmount) {
		var discountAmountPreRounding = 0;
		var discountAmount = 0;
		var roundedFinalAmount = 0;
		
		switch(reward.getAmountType()) {
			case "percentageOff" :
				discountAmountPreRounding = precisionEvaluate(arguments.originalAmount * (reward.getAmount()/100));
				break;
			case "amountOff" :
				discountAmountPreRounding = reward.getAmount();
				break;
			case "amount" :
				discountAmountPreRounding = precisionEvaluate(arguments.originalAmount - reward.getAmount());
				break;
		}
		
		if(!isNull(reward.getRoundingRule())) {
			roundedFinalAmount = getRoundingRuleService().roundValueByRoundingRule(value=precisionEvaluate(arguments.originalAmount - discountAmountPreRounding), roundingRule=reward.getRoundingRule());
			discountAmount = precisionEvaluate(arguments.originalAmount - roundedFinalAmount);
		} else {
			discountAmount = discountAmountPreRounding;
		}
		
		// This makes sure that the discount never exceeds the original amount
		if(discountAmountPreRounding > arguments.originalAmount) {
			discountAmount = arguments.originalAmount;
		}
		
		return numberFormat(discountAmount, "0.00");
	}
	
	// ----------------- END: Apply Promotion Logic -------------------------
	
	public struct function getSalePriceDetailsForProductSkus(required string productID) {
		var priceDetails = getUtilityService().queryToStructOfStructures(getDAO().getSalePricePromotionRewardsQuery(productID = arguments.productID), "skuID");
		for(var key in priceDetails) {
			if(priceDetails[key].roundingRuleID != "") {
				priceDetails[key].salePrice = getRoundingRuleService().roundValueByRoundingRuleID(value=priceDetails[key].salePrice, roundingRuleID=priceDetails[key].roundingRuleID);
			}
		}
		return priceDetails;
	}
	
	public struct function getShippingMethodOptionsDiscountAmountDetails(required any shippingMethodOption) {
		var details = {
			promotionID="",
			discountAmount=0
		};
		
		var promotionRewards = getDAO().getActivePromotionRewards( rewardTypeList="fulfillment", promotionCodeList=arguments.shippingMethodOption.getOrderFulfillment().getOrder().getPromotionCodeList() );
		
		// Loop over the Promotion Rewards to look for the best discount
		for(var i=1; i<=arrayLen(promotionRewards); i++) {
			var qc = 1;
			
			// Check to see if this requires any promotion codes
			if(arrayLen(promotionRewards[i].getPromotionPeriod().getPromotion().getPromotionCodes())) {
				// set the qc to 0 so that we can then 
				qc = 0;
				
				// loop over the promotion codes looking for 
			}
		}
		
		
		return details;
	}
	
	
		
}
