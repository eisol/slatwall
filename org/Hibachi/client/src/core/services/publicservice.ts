/// <reference path='../../../typings/hibachiTypescript.d.ts' />
/// <reference path='../../../typings/tsd.d.ts' />

import {Cart} from "../model/entity/cart";
import {Account} from "../model/entity/account";
import {PublicRequest} from "../model/transient/publicrequest";

class PublicService {


    public account:Account;
    public cart:any;
    public states:any;
    public countries:any;
    public addressOptions:any;
    public requests:{ [action: string]: PublicRequest; }={};
    public errors:{[key:string]:any}={};
    public newBillingAddress:any;
    public newCardInfo:any;
    public loading:boolean;
    public accountDataPromise:any;
    public addressOptionData:any;
    public cartDataPromise:any;
    public countryDataPromise:any;
    public stateDataPromise:any;

    public http:ng.IHttpService;
    public confirmationUrl:string;
    public header:any;
    public window:any;
    public finding:boolean;
    public rates:any;
    private baseActionPath = "";
    public months = [{name:'01 - JAN',value:1},{name:'02 - FEB',value:2},{name:'03 - MAR',value:3},{name:'04 - APR',value:4},{name:'05 - MAY',value:5},{name:'06 - JUN',value:6},{name:'07 - JUL',value:7},{name:'08 - AUG',value:8},{name:'09 - SEP',value:9},{name:'10 - OCT',value:10},{name:'11 - NOV',value:11},{name:'12 - DEC',value:12}];
    public years = [];
    public shippingAddress = "";
    public emailFulfillmentAddress:any;
    public billingAddress:any;
    public accountAddressEditFormIndex:any;
    public billingAddressEditFormIndex:any;
    public selectedBillingAddress:any;
    public editBillingAddress:any;
    public paymentMethods:any;
    public orderPlaced:boolean;
    public useShippingAsBilling:boolean;
    public saveShippingAsBilling:boolean;
    public saveCardInfo:boolean;
    public readyToPlaceOrder:boolean;
    public edit:String;
    public editPayment:boolean;
    public showCreateAccount:boolean;
    public imagePath:{[key:string]:any}={};

    ///index.cfm/api/scope/

    //@ngInject
    constructor(
        public $http:ng.IHttpService,
        public $q:ng.IQService,
        public $window:any,
        public $location:ng.ILocationService,
        public $hibachi:any,
        public $injector:ng.auto.IInjectorService,
        public requestService,
        public accountService,
        public cartService,
        public orderService,
        public observerService,
        public appConfig
    ) {
        this.orderService = orderService;
        this.cartService = cartService;
        this.accountService = accountService;
        this.requestService = requestService;
        this.appConfig = appConfig;
        this.baseActionPath = this.appConfig.baseURL+"/index.cfm/api/scope/"; //default path
        this.confirmationUrl = "/order-confirmation";
        this.$http = $http;
        this.$location = $location;
        this.$q = $q;
        this.$injector=$injector;
        this.getExpirationYears();
        this.$window = $window;
        this.$hibachi = $hibachi;
        this.cart = this.cartService.newCart();
        this.account = this.accountService.newAccount();
        this.observerService = observerService;
    }

    // public hasErrors = ()=>{

    //     return this.errors.length;
    // }

    /**
     * Helper methods for getting errors from the cart
     */
    public getErrors = ():{} =>{
        this.errors = {};
        for(var key in this.requests){
            var request = this.requests[key];
            if(Object.keys(request.errors).length){
                this.errors[key] = request.errors;
            }
         }

        return this.errors;
    }

    /** grab the valid expiration years for credit cards  */
    public getExpirationYears=():any =>{

        var baseDate = new Date();
        var today = baseDate.getFullYear();
        var start = today;
        for (var i = 0; i<= 15; i++){
            this.years.push(start + i);
        }
    }
    /** accessors for account */
    public getAccount=(refresh=false):any =>  {
        let urlBase = this.baseActionPath+'getAccount/';
        if(!this.accountDataPromise || refresh){
            this.accountDataPromise = this.getData(urlBase, "account", "");
        }
        return this.accountDataPromise;
    }
    /** accessors for cart */
    public getCart=(refresh=false):any =>  {
        let urlBase = this.baseActionPath+'getCart/';
        if(!this.cartDataPromise || refresh){
            this.cartDataPromise = this.getData(urlBase, "cart", "");
        }
        return this.cartDataPromise;
    }
    /** accessors for countries */
    public getCountries=(refresh=false):any =>  {
        let urlBase = this.baseActionPath+'getCountries/';
        if(!this.countryDataPromise || refresh){
            this.countryDataPromise = this.getData(urlBase, "countries", "");
        }
        return this.countryDataPromise;
    }

    /** accessors for states */
    public getStates=(countryCode:string, refresh=false):any =>  {
       if (!angular.isDefined(countryCode)) countryCode = "US";
       let urlBase = this.baseActionPath+'getStateCodeOptionsByCountryCode/';
       if(!this.stateDataPromise || refresh){
           this.stateDataPromise = this.getData(urlBase, "states", "?countryCode="+countryCode);
       }
       return this.stateDataPromise;
    }

    public getStateByStateCode = (stateCode)=>{
        if (!angular.isDefined(this.states) || !angular.isDefined(this.states.stateCodeOptions) || !angular.isDefined(stateCode)){
            return;
        }
        for (var state in this.states.stateCodeOptions){
            if (this.states.stateCodeOptions[state].value == stateCode){
                return this.states.stateCodeOptions[state];
            }
        }
    }

    /** accessors for states */
    public getAddressOptions=(countryCode:string, refresh=false):any =>  {
       if (!angular.isDefined(countryCode)) countryCode = "US";
       let urlBase = this.baseActionPath+'getAddressOptionsByCountryCode/';
       if(!this.addressOptionData || refresh){
           this.addressOptionData = this.getData(urlBase, "addressOptions", "&countryCode="+countryCode);
       }
       return this.addressOptionData;
    }

    /** accessors for states */
    public getData=(url, setter, param):any =>  {

        let urlBase = url + param;
        let request = this.requestService.newPublicRequest(urlBase);

        request.promise.then((result:any)=>{
            //don't need account and cart for anything other than account and cart calls.
            if (setter.indexOf('account') == -1 || setter.indexOf('cart') == -1){
                if (result['account']){delete result['account'];}
                if (result['cart']){delete result['cart'];}
            }

            if(setter == 'cart'||setter=='account'){
                //cart and account return cart and account info flat
                this[setter].populate(result);

            }else{
                //other functions reutrn cart,account and then data
                this[setter]=(result);
            }

        }).catch((reason)=>{


        });
        this.requests[request.getAction()]=request;
        return request.promise;
    }

    /** sets the current shipping address */
    public setShippingAddress=(shippingAddress) => {
        this.shippingAddress = shippingAddress;
    }

    /** sets the current shipping address */
    public setBillingAddress=(billingAddress) => {
        this.billingAddress = billingAddress;
    }

    /** this is the generic method used to call all server side actions.
    *  @param action {string} the name of the action (method) to call in the public service.
    *  @param data   {object} the params as key value pairs to pass in the post request.
    *  @return a deferred promise that resolves server response or error. also includes updated account and cart.
    */
    public doAction=(action:string, data?:any, method?:any) => {

        if (!action) {throw "Action is required exception";}

        var urlBase = "";
		
        //check if the caller is defining a path to hit, otherwise use the public scope.
        if (action.indexOf(":") !== -1){
            urlBase = action; //any path
        }else{
            urlBase = "/index.cfm/api/scope/" + action;//public path
        }
        
        if(data){
            method = "post";
            data.returnJsonObjects = "cart,account";
        }else{
            urlBase += "&returnJsonObject=cart,account";
        }

        if (method == "post"){
             data.returnJsonObjects = "cart,account";
             console.log('urlBase', urlBase, 'data', data, 'method', method);
            //post
            let request:PublicRequest = this.requestService.newPublicRequest(urlBase,data,method)
            request.promise.then((result:any)=>{
                this.processAction(result,request);
            }).catch((response)=>{

            });
            this.requests[request.getAction()]=request;
            return request.promise;
        }else{
            //get

            var url = urlBase + "&returnJsonObject=cart,account";

            let request = this.requestService.newPublicRequest(url);
            request.promise.then((result:any)=>{
                this.processAction(result,request);
            }).catch((reason)=>{

            });

            this.requests[request.getAction()]=request;
            return request.promise;
        }

    }

    private processAction = (response,request:PublicRequest)=>{
        /** update the account and the cart */

        this.account.populate(response.account);
        this.account.request = request;
        this.cart.populate(response.cart);
        this.cart.request = request;

        //if the action that was called was successful, then success is true.
        if (request.hasSuccessfulAction()){
            for (var action in request.successfulActions){
                if (request.successfulActions[action].indexOf('public:cart.placeOrder') !== -1){
                    this.$window.location.href = this.confirmationUrl;
                }
            }
        }
        if (!request.hasSuccessfulAction()){
            //this.hasErrors = true;
        }

    }

    public getRequestByAction = (action:string)=>{
        return this.requests[action];
    }

    /**
     * Helper methods so that everything in account and cart can be accessed using getters.
     */
    public userIsLoggedIn = ():boolean =>{
       return this.account.userIsLoggedIn();
    }

    public getActivePaymentMethods = ()=>{
        let urlString = "/?slataction=admin:ajax.getActivePaymentMethods";
        let request = this.requestService.newPublicRequest(urlString)
        .then((result:any)=>{
            if (angular.isDefined(result.data.paymentMethods)){
                this.paymentMethods = result.data.paymentMethods;
            }
        });
        this.requests[request.getAction()]=request;
    };

    /**
     * Given a payment method name, returns the id.
     */
    public getPaymentMethodID = (name)=>{
        for (var method in this.paymentMethods){
            if (this.paymentMethods[method].paymentMethodName == name && this.paymentMethods[method].activeFlag == "Yes "){
                return this.paymentMethods[method].paymentMethodID;
            }
        }
    }

    public hasPaymentMethod = (paymentMethodName)=>{
        for (var payment of this.cart.orderPayments){
            if(payment.paymentMethod.paymentMethodName === paymentMethodName) return true;
        }
        return false;
    }

    public hasCreditCardPaymentMethod = ()=>{
        return this.hasPaymentMethod("Credit Card");
    }

    public hasPaypalPaymentMethod = ()=>{
        return this.hasPaymentMethod("PayPal Express");
    }

    public hasGiftCardPaymentMethod = ()=>{
        return this.hasPaymentMethod("Gift Card");
    }

    public hasMoneyOrderPaymentMethod = ()=>{
        return this.hasPaymentMethod("Money Order");
    }
    public hasCashPaymentMethod = ()=>{
        return this.hasPaymentMethod("Cash");
    }

    public hasFulfillmentMethod = (fulfillmentMethodName) => {
        for (var fulfillment of this.cart.orderFulfillments){
            if(fulfillment.fulfillmentMethod.fulfillmentMethodName === fulfillmentMethodName) return true;
        }
        return false;
    }

    public hasShippingFulfillmentMethod = ()=>{
        return this.hasFulfillmentMethod("Shipping");
    }

    public hasEmailFulfillmentMethod = ()=>{
        return this.hasFulfillmentMethod("Email");
    }

    public hasPickupFulfillmentMethod = ()=>{
        return this.hasFulfillmentMethod("Pickup");
    }

    /** Returns true if the order requires a fulfillment */
    public orderRequiresFulfillment = ():boolean=> {

        return this.cart.orderRequiresFulfillment();
    };

    /**
     *  Returns true if the order requires a account
     *  Either because the user is not logged in, or because they don't have one.
     *
     */
    public orderRequiresAccount = ():boolean=> {
        return this.cart.orderRequiresAccount();
    };

    /** Returns true if the payment tab should be active */
    public hasShippingAddressAndMethod = ():boolean => {
        return this.cart.hasShippingAddressAndMethod();
    };

    /**
     * Returns true if the user has an account and is logged in.
     */
    public hasAccount = ():boolean=>{
        if ( this.account.accountID ) {
            return true;
        }
        return false;
    }

    /** Redirects to the order confirmation page if the order placed successfully
    */
    public redirectExact = (url:string)=>{
        this.$location.url(url);
    }

    // /** Returns true if a property on an object is undefined or empty. */
    public isUndefinedOrEmpty = (object, property)=> {
        if (!angular.isDefined(object[property]) || object[property] == ""){
            return true;
        }
        return false;
    }

    /** A simple method to return the quantity sum of all orderitems in the cart. */
    public getOrderItemQuantitySum = ()=>{
        var totalQuantity = 0;
        if (angular.isDefined(this.cart)){
            return this.cart.getOrderItemQuantitySum();
        }
        return totalQuantity;
    }
    /** Returns the index of the state from the list of states */
    public getSelectedStateIndexFromStateCode = (stateCode, states)=>{
        for (var state in states){
            if (states[state].value == stateCode){
                return state;
            }
        }
    }

    /**
     * Returns true if on a mobile device. This is important for placeholders.
     */
     public isMobile = ()=>{
           if(this.$window.innerWidth <= 800 && this.$window.innerHeight <= 600) {
             return true;
           }
           return false;
     };

     /** returns true if the shipping method is the selected shipping method
     */
     public isSelectedShippingMethod = (index, value)=>{
        if (this.cart.fulfillmentTotal &&
              value == this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingMethod.shippingMethodID ||
              this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingMethodOptions.length == 1){
                return true;
              }
              return false;
     }

     /** returns the index of the selected shipping method.
     */
     public getSelectedShippingIndex = (index, value)=>{
        for (var i = 0; i <= this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingMethodOptions.length; i++){
            if (this.cart.fulfillmentTotal == this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingMethodOptions[i].totalCharge){
                return i;
            }
        }
     }

     /** simple validation just to ensure data is present and accounted for.
     */
    public validateNewOrderPayment =  (newOrderPayment)=> {
        var newOrderPaymentErrors = {};
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.billingAddress.streetAddress')){
            newOrderPaymentErrors['streetAddress'] = 'Required *';
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.billingAddress.countrycode')){
            newOrderPaymentErrors['countrycode'] = 'Required *';
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.billingAddress.statecode')){
            if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.billingAddress.locality')){
                newOrderPaymentErrors['statecode'] = 'Required *';
            }
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.billingAddress.city')){
            if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.billingAddress.city')){
                newOrderPaymentErrors['city'] = 'Required *';
            }
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.billingAddress.locality')){
            if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.billingAddress.statecode')){
                newOrderPaymentErrors['locality'] = 'Required *';
            }
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.billingAddress.postalcode')){
            newOrderPaymentErrors['postalCode'] = 'Required *';
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.nameOnCreditCard')){
            newOrderPaymentErrors['nameOnCreditCard']= 'Required *';
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.expirationMonth')){
            newOrderPaymentErrors['streetAddress'] = 'Required *';
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.expirationYear')){
            newOrderPaymentErrors['expirationYear'] = 'Required *';
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.creditCardNumber')){
            newOrderPaymentErrors['creditCardNumber'] = 'Required *';
        }
        if (this.isUndefinedOrEmpty(newOrderPayment, 'newOrderPayment.securityCode')){
            newOrderPaymentErrors['securityCode'] = 'Required *';
        }
        if (Object.keys(newOrderPaymentErrors).length){
            // this.cart.orderPayments.hasErrors = true;
            // this.cart.orderPayments.errors = newOrderPaymentErrors;
        }
    }

    public orderPaymentKeyCheck = (event) =>{
        if(event.event.keyCode == 13 ){
            this.setOrderPaymentInfo();
        }
    }

    // Prepare swAddressForm billing address / card info to be passed to addOrderPayment
    public setOrderPaymentInfo = () => {
        let billingAddress;
        
        //if selected, pass shipping address as billing address
        if(this.useShippingAsBilling){
            billingAddress = this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].data.shippingAddress;
        
        //If account address selected, use that
        }else if(!this.billingAddressEditFormIndex || this.billingAddressEditFormIndex == ''){
            billingAddress = this.selectedBillingAddress;
        
        //If creating new address, get from form
        }else if(this.billingAddressEditFormIndex == 'new'){
            billingAddress = this.billingAddress.getData();
        
        //If editing existing account address, get from form
        }else{
            billingAddress = this.editBillingAddress.getData();
        }

        //Add card info
        for(let key in this.newCardInfo){
            billingAddress[key] = this.newCardInfo[key];
        }
        
        this.newBillingAddress = billingAddress;
        this.addOrderPayment({});
    }

    /** Allows an easy way to calling the service addOrderPayment.
    */
    public addOrderPayment = (formdata)=>{
        //reset the form errors.
        // this.cart.hasErrors=false;
        // this.cart.orderPayments.errors = {};
        // this.cart.orderPayments.hasErrors = false;

        //Grab all the data
        var billingAddress  = this.newBillingAddress;
        var expirationMonth = formdata.month;
        var expirationYear  = formdata.year;
        var country         = formdata.country;
        var state           = formdata.state;
        var accountFirst    = this.account.firstName;
        var accountLast     = this.account.lastName;
        var data = {};

        var processObject = this.orderService.newOrder_AddOrderPayment();
        data = {
            'newOrderPayment.billingAddress.addressID':'',
            'newOrderPayment.billingAddress.streetAddress': billingAddress.streetAddress,
            'newOrderPayment.billingAddress.street2Address': billingAddress.street2Address,
            'newOrderPayment.nameOnCreditCard': billingAddress.nameOnCreditCard,
            'newOrderPayment.billingAddress.name': billingAddress.nameOnCreditCard,
            'newOrderPayment.expirationMonth': expirationMonth || billingAddress.selectedMonth,
            'newOrderPayment.expirationYear': expirationYear || billingAddress.selectedYear,
            'newOrderPayment.billingAddress.countrycode': country || billingAddress.countrycode,
            'newOrderPayment.billingAddress.city': ''+billingAddress.city,
            'newOrderPayment.billingAddress.statecode': state || billingAddress.statecode,
            'newOrderPayment.billingAddress.locality': billingAddress.locality || '',
            'newOrderPayment.billingAddress.postalcode': billingAddress.postalcode,
            'newOrderPayment.securityCode': billingAddress.cvv,
            'newOrderPayment.creditCardNumber': billingAddress.cardNumber,
            'newOrderPayment.saveShippingAsBilling':(this.saveShippingAsBilling == true),
            'newOrderPayment.creditCardLastFour': billingAddress.cardNumber ? billingAddress.cardNumber.slice(-4) : '',
            'accountPaymentMethodID': billingAddress.accountPaymentMethodID,
            'copyFromType': billingAddress.copyFromType,
            'saveAccountPaymentMethodFlag': this.saveCardInfo
        };
        //processObject.populate(data);

        //Make sure we have required fields for a newOrderPayment.
        this.validateNewOrderPayment( data );
        if ( this.cart.orderPayments.hasErrors && Object.keys(this.cart.orderPayments.errors).length ){
            return -1;
        }

        //Post the new order payment and set errors as needed.
        this.doAction('addOrderPayment', data, 'post').then((result)=>{
            var serverData = result;

            if (serverData.cart.hasErrors || angular.isDefined(this.cart.orderPayments[this.cart.orderPayments.length-1]['errors']) && !this.cart.orderPayments[this.cart.orderPayments.length-1]['errors'].hasErrors){
                this.cart.hasErrors = true;
                this.readyToPlaceOrder = true;
            }else{
                this.editPayment = false;
                this.readyToPlaceOrder = true;
            }
        });
    };

    /** Allows an easy way to calling the service addOrderPayment.
                    */
    public addGiftCardOrderPayments = (redeemGiftCardToAccount)=>{
        //reset the form errors.
        this.cart.hasErrors=false;
        this.cart.orderPayments.errors = {};
        this.cart.orderPayments.hasErrors = false;
        this.finding = true;
        
        //Grab all the data
        var giftCards = [];
        if (angular.isDefined(this.account.giftCards)){
            giftCards = this.account.giftCards;    
         }
        
        var data = {};
        
        data = {
            'newOrderPayment.paymentMethod.paymentMethodID':'50d8cd61009931554764385482347f3a',
            'newOrderPayment.redeemGiftCardToAccount':redeemGiftCardToAccount,
        };
        
        //add the amounts from the gift cards
        for (var card in giftCards){
            if (giftCards[card].applied == true){
                
                //If the amount on the card is not enough to cover the balance, then use the full balance.
                
                //find the orderAmountNeeded
                if (this.cart.orderPayments.length){
                    for (var payment in this.cart.orderPayments){
                        if (this.cart.orderPayments[payment].paymentMethod != null &&    
                            this.cart.orderPayments[payment].paymentMethod.paymentMethodName == "Gift Card"
                        ){
                            if (angular.isDefined(this.cart.orderPayments[payment].orderAmountNeeded)){
                                var remainingBalance = this.cart.orderPayments[payment].orderAmountNeeded;
                                break;
                            }
                        }
                    }
                }
                
                //Base the balance off of the balanceAmount.
                if (!angular.isDefined(remainingBalance)){
                    var remainingBalance = giftCards[card].balanceAmount || giftCards[card].calculatedBalanceAmount;    
                }
                
                if (this.cart.calculatedTotal > remainingBalance){
                    data['newOrderPayment.amount'] = remainingBalance;
                }else{
                    data['newOrderPayment.amount'] = this.cart.calculatedTotal;
                }
                data['newOrderPayment.order.account.accountID'] = this.account.accountID;
                data['newOrderPayment.giftCardNumber'] = giftCards[card].giftCardCode;
                data['copyFromType'] = "";
                
                this.doAction('addOrderPayment', data, 'post').then((result:any)=>{
                    var serverData
                    if (angular.isDefined(result)){
                        serverData = result;
                        if (serverData.cart.hasErrors){                            
                            this.cart.hasErrors = true;
                            this.readyToPlaceOrder = false;
                            this.edit = '';
                        }
                    }else{
                        
                    }
                });   
            }
        }
              
    };

    /** returns the index of the last selected shipping method. This is used to get rid of the delay.
    */
    public selectShippingMethod = (index)=>{
        for (var method in this.lastSelectedShippingMethod){
            if (method != index){
                this.lastSelectedShippingMethod[method] = 'false';
            }
        }
        this.lastSelectedShippingMethod[index] = 'true';
    }

    /** returns true if this was the last selected method
    */
    public isLastSelectedShippingMethod = (index)=>{
        if (this.lastSelectedShippingMethod[index] === 'true'){
            return true;
        }
        return false;
    }

    /** Allows an easy way to calling the service addOrderPayment.
    */
    public addOrderPaymentAndPlaceOrder = (formdata)=>{
        //reset the form errors.
        this.orderPlaced = false;
        //Grab all the data
        var billingAddress  = this.newBillingAddress;
        var expirationMonth = formdata.month;
        var expirationYear  = formdata.year;
        var country         = formdata.country;
        var state           = formdata.state;
        var accountFirst    = this.account.firstName;
        var accountLast     = this.account.lastName;
        var data = {};

        data = {
            'orderid':this.cart.orderID,
            'newOrderPayment.billingAddress.streetAddress': billingAddress.streetAddress,
            'newOrderPayment.billingAddress.street2Address': billingAddress.street2Address,
            'newOrderPayment.nameOnCreditCard': billingAddress.nameOnCard || accountFirst + ' ' +accountLast,
            'newOrderPayment.expirationMonth': expirationMonth,
            'newOrderPayment.expirationYear': expirationYear,
            'newOrderPayment.billingAddress.countrycode': country || billingAddress.countrycode,
            'newOrderPayment.billingAddress.city': '' + billingAddress.city,
            'newOrderPayment.billingAddress.statecode': state || billingAddress.statecode,
            'newOrderPayment.billingAddress.locality': billingAddress.locality || '',
            'newOrderPayment.billingAddress.postalcode': billingAddress.postalcode,
            'newOrderPayment.securityCode': billingAddress.cvv,
            'newOrderPayment.creditCardNumber': billingAddress.cardNumber,
            'newOrderPayment.saveShippingAsBilling':(this.saveShippingAsBilling == true),
        };

        //Make sure we have required fields for a newOrderPayment.
        //this.validateNewOrderPayment( data );
        if ( this.cart.orderPayments.hasErrors && Object.keys(this.cart.orderPayments.errors).length ){

            return -1;
        }

        //Post the new order payment and set errors as needed.
        this.$q.all([this.doAction('addOrderPayment,placeOrder', data, 'post')]).then((result)=>{
            var serverData
            if (angular.isDefined(result['0'])){
                serverData = result['0'].data;
            }else{

            }//|| angular.isDefined(serverData.cart.orderPayments[serverData.cart.orderPayments.length-1]['errors']) && slatwall.cart.orderPayments[''+slatwall.cart.orderPayments.length-1]['errors'].hasErrors
            if (serverData.cart.hasErrors || (angular.isDefined(serverData.failureActions) && serverData.failureActions.length && serverData.failureActions[0] == "public:cart.addOrderPayment")){
                if (serverData.failureActions.length){
                    for (var action in serverData.failureActions){
                        //
                    }
                }
                this.edit = '';
                return true;
            } else if (serverData.successfulActions.length) {
                //
                this.cart.hasErrors = false;
                this.editPayment = false;
                this.edit = '';
                for (var action in serverData.successfulActions){
                    //
                    if (serverData.successfulActions[action].indexOf("placeOrder") != -1){
                        //if there are no errors then redirect.
                        this.orderPlaced = true;
                        this.redirectExact('/order-confirmation/');
                    }
                }
            }else{
                this.edit = '';
            }
        });

    };

    //Applies a giftcard from the user account onto the payment.
    public applyGiftCard = (giftCardCode)=>{
        this.finding = true;
        //set the card to applied
        var giftCard = {
            "giftCardCode":giftCardCode,
            "applied":true
        };
        this.account.giftCards.push(giftCard);
        this.addGiftCardOrderPayments(true);
        this.finding = false;
    };

    public formatPaymentMethod = (paymentMethod) =>{
        return paymentMethod.nameOnCreditCard + ' - ' + paymentMethod.creditCardType + ' *' + paymentMethod.creditCardLastFour + ' exp. ' + ('0' + paymentMethod.expirationMonth).slice(-2) + '/' + paymentMethod.expirationYear.toString().slice(-2)
    }

    public setLocationPreference = (storeData)=>{
                
                this.loading = true;
                this.tempStoreData = storeData;
                //send here if we are updating the value on the order, account, and orderFulfillment.
                var url = this.getUrl();
                if (url.indexOf('my-account') == -1){
                    var params = "/?slataction=totalwine:ajax.setLocationPreference&ajaxRequest=1&returnJsonObject=account&locationID=" + storeData;
                    
                    //if we also want to set this on the account, then set this flag.
                    if (url.indexOf('checkout') > 0){
                        params = params + "&setPreferenceOnAccountFlag=true";
                    }
                    
                    this.$http.get(params).then((result)=>{
                        
                        this.stores = undefined;
                        if (result.data.account != undefined){
                            this.account.data.preferredLocation = result.data.account.preferredLocation;

                        }
                        if (result.data.cart != undefined){
                            this.cart.data.orderFulfillments = result.data.cart.orderFulfillments;
                            this.cart.data = result.data.cart;
                        }
                        this.loading = false;
                    });
                
                //send here if we are just updating the value on the account. /my-account
                } else {
                    if (this.account.accountID != undefined && this.account.accountID != ""){
                        this.$http.get("/?slataction=totalwine:ajax.setLocationPreferenceOnAccount&ajaxRequest=1&returnJsonObject=account&locationID=" + storeData).then((result)=>{
                            
                                this.stores = undefined;
                                if (result.data.account != undefined){
                                    this.account.data.preferredLocation = result.data.account.preferredLocation;
                                }
                        });
                    }
                    this.loading = false;
                }
               
            $(window).load(()=>{
                $('#locationModal').modal('hide');
            });
            this.showLocationModal = false;
               this.resumeAddOrderItems();
                
           };

    public getResizedImageByProfileName = (profileName, skuIDList)=>{
               
       this.loading = true;
       
       if (profileName == undefined){
           profileName = "medium";
       }
       
       this.$http.get("/index.cfm/api/scope/?context=getResizedImageByProfileName&profileName="+profileName+"&skuIds="+skuIDList).success((result:any)=>{
            if(!angular.isDefined(this.imagePath)){
                this.imagePath = {};
            }
            this.imagePath[skuIDList] = "";
            
            result = angular.fromJson(result);
            if (angular.isDefined(result.resizedImagePaths) && angular.isDefined(result.resizedImagePaths.resizedImagePaths) && result.resizedImagePaths.resizedImagePaths[0] != undefined){
                
                this.imagePath[skuIDList] = result.resizedImagePaths.resizedImagePaths[0];
                this.loading = false;
                return this.imagePath[skuIDList];
                
            }else{
                this.loading = false;
                return "";
            }
            
         });
        
     };

    //returns the amount total of giftcards added to this account.
    public getAppliedGiftCardTotals = ()=>{
        //
        var total = 0;
        for (var payment in this.cart.orderPayments){
            if (this.cart.orderPayments[payment].giftCardNumber != ""){
                total = total + Number(this.cart.orderPayments[payment]['amount'].toFixed(2));
            }
        }
        return total;
    };

    //gets the calcuated total minus the applied gift cards.
    public getTotalMinusGiftCards = ()=>{
        var total = this.getAppliedGiftCardTotals();
        return this.cart.calculatedTotal - total;
    };

    //get estimated shipping rates given a weight, from to zips
    public getEstimatedRates = (zipcode)=>{

        var weight = 0;
        for (var item in this.cart.orderFulfillments){

            weight += this.cart.orderFulfillments[item].totalShippingWeight;
        }
        var shipFromAddress = {
            "postalcode": ""
        };
        var shipToAddress = {
            "postalcode": zipcode
        };
        var totalWeight = weight;

        //get the rates.
        let urlString = "?slataction=admin:ajax.getEstimatedShippingRates&shipFromAddress="+ JSON.stringify(shipFromAddress)
        +"&shipToAddress="+ JSON.stringify(shipToAddress) +"&totalWeight=" + JSON.stringify(weight);

        let request = this.requestService.newPublicRequest(urlString)
        .then((result:any)=>{

            this.rates = result.data;
        });
    }

    
    /** Returns the state from the list of states by stateCode */
    public getStateByStateCode = (stateCode) => {
     	for (var state in this.states.stateCodeOptions){
     		if (this.states.stateCodeOptions[state].value == stateCode){
     			return this.states.stateCodeOptions[state];
     		}
     	}
    }
     
    /** Returns the state from the list of states by stateCode */
    public resetRequests = (request) => {
     	delete this.requests[request];
    }
    
    /** Returns true if the addresses match. */
    public addressesMatch = (address1, address2) => {
    	if (angular.isDefined(address1) && angular.isDefined(address2)){
        	if ( (address1.streetAddress == address2.streetAddress && 
	            address1.street2Address == address2.street2Address &&
	            address1.city == address2.city &&
	            address1.postalcode == address2.postalcode &&
	            address1.countrycode == address2.countrycode)){
            	return true;
            }
        }
        return false;
    }
    
    /** Should be pushed down into core. Returns the profile image by name. */
   	public getResizedImageByProfileName = (profileName, skuIDList) => {
   		this.imagePath = {};
   		
   		if (profileName == undefined){
   			profileName = "medium";
   		}
   		
   		this.$http.get("/index.cfm/api/scope/?context=getResizedImageByProfileName&profileName="+profileName+"&skuIds="+skuIDList).success((result:any)=>{
   		 	
   		 	this.imagePath[skuIDList] = "";
   		 	
   		 	result = <any>angular.fromJson(result);
   		 	if (angular.isDefined(result.resizedImagePaths) && angular.isDefined(result.resizedImagePaths.resizedImagePaths) && result.resizedImagePaths.resizedImagePaths[0] != undefined){
   		 		
   		 		this.imagePath[skuIDList] = result.resizedImagePaths.resizedImagePaths[0];
   		 		this.loading = false;
   		 		return this.imagePath[skuIDList];
   		 		
   		 	}else{
   		 		return "";
   		 	}
   		 	
   		}); 
   	}

      /**
     *  Returns true when the fulfillment body should be showing
     *  Show if we don't need an account but do need a fulfillment
     *
     */
    public showFulfillmentTabBody = ()=> {
        if(!this.hasAccount()) return false;
        if ((this.cart.orderRequirementsList.indexOf('account') == -1) && this.account.accountID &&
            (this.cart.orderRequirementsList.indexOf('fulfillment') != -1) ||
            (this.cart.orderRequirementsList.indexOf('fulfillment') == -1) &&
                (this.edit == 'fulfillment')) {
            return true;
        }
        return false;
    };
    /**
     *  Returns true when the fulfillment body should be showing
     *  Show if we don't need an account,fulfillment, and don't have a payment - or
     *  we have a payment but are editting the payment AND nothing else is being edited
     *
     */
   
    public showPaymentTabBody = ()=> {
        if(!this.hasAccount()) return false;
        if ((this.cart.orderRequirementsList.indexOf('account') == -1) && this.account.accountID &&
            (this.cart.orderRequirementsList.indexOf('fulfillment') == -1) &&
            (this.cart.orderRequirementsList.indexOf('payment') != -1) && this.edit == '' ||
            (this.cart.orderRequirementsList.indexOf('payment') == -1) &&
                (this.edit == 'payment')) {
            return true;
        }
        return false;
    };

    /**
     *  Returns true if the review tab body should be showing.
     *  Show if we don't need an account,fulfillment,payment, but not if something else is being edited
     *
     */
    public showReviewTabBody = ()=> {
        if(!this.hasAccount()) return false;
        if ((this.cart.orderRequirementsList.indexOf('account') == -1) && this.account.accountID &&
            (this.cart.orderRequirementsList.indexOf('fulfillment') == -1) &&
            (this.cart.orderRequirementsList.indexOf('payment') == -1) &&
            (this.edit == '') || (this.edit == 'review')) {
            return true;
        }
        return false;
    };
    /** Returns true if the fulfillment tab should be active */
    public fulfillmentTabIsActive = ()=> {
        if(!this.hasAccount()) return false;

        if ((this.edit == 'fulfillment') ||
            (this.edit == '' && ((this.cart.orderRequirementsList.indexOf('account') == -1) && this.account.accountID) &&
                (this.cart.orderRequirementsList.indexOf('fulfillment') != -1))) {
            return true;
        }
        return false;
    };

    /** Returns true if the payment tab should be active */
    public paymentTabIsActive = ()=> {
        if(!this.hasAccount()) return false;
        if ((this.edit == 'payment') ||
            (this.edit == '' &&
                (this.cart.orderRequirementsList.indexOf('account') == -1) && this.account.accountID &&
                (this.cart.orderRequirementsList.indexOf('fulfillment') == -1) &&
                (this.cart.orderRequirementsList.indexOf('payment') != -1))) {
            return true;
        }
        return false;
    };

    public isCreatingAccount = () =>{
        return !this.hasAccount() && this.showCreateAccount;
    }

    public isSigningIn = () =>{
        return !this.hasAccount() && !this.showCreateAccount;
    }

    public loginError = () => {
        if(this.account.processObjects && this.account.processObjects.login && this.account.processObjects.login.hasErrors){
            return this.account.processObjects.login.errors.emailAddress['0'];
        };
    }

    public createAccountError = () =>{
        if(this.account.processObjects && this.account.processObjects.create && this.account.processObjects.create.hasErrors){
            return this.account.processObjects.create.errors;
        }
    }

    public forgotPasswordNotSubmitted = () =>{
        return !this.account.processObjects || (!this.account.hasErrors && !this.account.processObjects.forgotPassword);
    }
    public forgotPasswordSubmitted = () =>{
        return this.account.processObjects && this.account.processObjects.forgotPassword;
    }
    public forgotPasswordHasNoErrors = ()=>{
        return this.account.processObjects && this.account.processObjects.forgotPassword && !this.account.processObjects.forgotPassword.hasErrors
    }

    public forgotPasswordError = ()=>{
        if(this.forgotPasswordSubmitted() && !this.forgotPasswordHasNoErrors()){
            return this.account.processObjects.forgotPassword.errors.emailAddress['0']
        }
    }

    public hideAccountAddressForm = ()=>{
        this.accountAddressEditFormIndex = undefined;
    }

    public showEditAccountAddressForm = ()=>{
        return this.accountAddressEditFormIndex != undefined && this.accountAddressEditFormIndex != 'new';
    }

    public showNewAccountAddressForm = ()=>{
        return this.accountAddressEditFormIndex == 'new';
    }

    public showNewBillingAddressForm = ()=>{
        return !this.useShippingAsBilling && this.billingAddressEditFormIndex == 'new'
    }

    public showEditBillingAddressForm = ()=>{
        return !this.useShippingAsBilling && this.billingAddressEditFormIndex && this.billingAddressEditFormIndex != 'new'
    }

    public accountAddressIsSelectedShippingAddress = (key) =>{
        if(this.account && 
           this.account.accountAddresses &&
           this.cart.orderFulfillments &&
           this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex] &&
           this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingAddress){
            return (
                this.account.accountAddresses[key].address.streetAddress === this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingAddress.streetAddress &&
                this.account.accountAddresses[key].address.street2Address === this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingAddress.street2Address &&
                this.account.accountAddresses[key].address.city === this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingAddress.city &&
                this.account.accountAddresses[key].address.statecode === this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingAddress.statecode &&
                this.account.accountAddresses[key].address.postalcode === this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingAddress.postalcode &&
                this.account.accountAddresses[key].address.countrycode === this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].shippingAddress.countrycode)
        }        
        return false;
    }

    public hasEmailFulfillmentAddress = ()=>{
        return this.cart.orderFulfillmentWithEmailTypeIndex > -1 && this.cart.orderFulfillments[this.cart.orderFulfillmentWithEmailTypeIndex].emailAddress
    }
    public getPickupLocation = () => {
        if(!this.cart.data.orderFulfillments[this.cart.orderFulfillmentWithPickupTypeIndex]) return;
        return this.cart.data.orderFulfillments[this.cart.orderFulfillmentWithPickupTypeIndex].pickupLocation;
    }

    public getShippingAddress = () =>{
        if(!this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex]) return;
        return this.cart.orderFulfillments[this.cart.orderFulfillmentWithShippingMethodOptionsIndex].data.shippingAddress;
    }

    public getEmailFulfillmentAddress = () =>{
        if(!this.cart.orderFulfillments[this.cart.orderFulfillmentWithEmailTypeIndex]) return;
        return this.cart.orderFulfillments[this.cart.orderFulfillmentWithEmailTypeIndex].emailAddress;
    }

    public namelessPickupLocation = () => {
        if(!this.getPickupLocation()) return false;
        return this.getPickupLocation().primaryAddress != undefined && this.getPickupLocation().locationName == undefined
    }

    public noPickupLocation = () => {
        if(!this.getPickupLocation()) return true;
        return this.getPickupLocation().primaryAddress == undefined && this.getPickupLocation().locationName == undefined
    }

    public hasAccountPaymentMethods = () => {
        return this.account && this.account.accountPaymentMethods && this.account.accountPaymentMethods.length
    }

    public showBillingAccountAddresses = () =>{
        return !this.useShippingAsBilling && !this.billingAddressEditFormIndex;
    }

    public hasNoCardInfo = () =>{
        return !this.newCardInfo || !this.newCardInfo.nameOnCreditCard || !this.newCardInfo.cardNumber || !this.newCardInfo.cvv;
    }

    public isGiftCardPayment = (payment) =>{
        return payment.giftCard && payment.giftCard.giftCardCode;
    }

    public orderHasNoPayments = () =>{
        return !this.cart.orderPayments.length
    }

    public hasProductNameAndNoSkuName = (orderItem) =>{
        return !orderItem.sku.skuName && orderItem.sku.product && orderItem.sku.product.productName
    }

}
export {PublicService};

