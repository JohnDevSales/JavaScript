@RestResource(urlMapping='/api/infoStatus/v1')
global with sharing class UpdateStatusBoxLink {
    
    @HttpPost
    global static void  updateStatusOMS() {
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            List<data> data = (List<data>)JSON.deserialize(req.requestBody.toString(), List<data>.class);
            

            map<String, String> mapParams = new map<String, String>{};
			Set<String> trackersSet = new Set <String>();
			Set<String> statusSet = new Set <String>();
            map<String,string> mapError = new map<String,string>{};
			map<String, String> mapDate = new map<String, String>();  // MAPA NOVO

                
                for(data stepToAdd : data){ 
                    if(!String.isBlank(stepToAdd?.rastreadorTMS) && !String.isBlank(stepToAdd?.tipo) && !String.isBlank(stepToAdd?.dataEvento)){
                        
                        trackersSet.add(stepToAdd.rastreadorTMS);
                        statusSet.add(stepToAdd.tipo);
                        mapParams.put(stepToAdd.rastreadorTMS, stepToAdd.tipo);
                        mapDate.put(stepToAdd.rastreadorTMS, stepToAdd.dataEvento);    // INSERT NO MAP
                       
                }else{
					mapError.put( stepToAdd.rastreadorTMS, stepToAdd.tipo );
                    }
                }
                        system.debug('trackersSet --->' + trackersSet); //DEBUG
                        system.debug('statusSet --->' + statusSet); //DEBUG
                        system.debug('mapParams --->' + mapParams); //DEBUG
						system.debug('mapDate --->' + mapDate); //DEBUG

            
            map<String, String> mapStatusMDT = new map<String, String>{};           
              for(Atonit_Mktplace_StatusOMSBoxlink_mdt listStatusVerified : [SELECT DeveloperName, Label  FROM Atonit_Mktplace_StatusOMSBoxlink_mdt 
                                                                                    WHERE DeveloperName IN :statusSet]){ 
                        
               mapStatusMDT.put(listStatusVerified.DeveloperName, listStatusVerified.Label); 
                  }
				
            	system.debug('mapStatusMDT --->' + mapStatusMDT); //DEBUG

            
            List<Atonit_Mktplace_Seller_Shipment_c> listOrdersByTrackers = [SELECT 
                                                                              Atonit_Mktplace_Seller_Order_c,
                                                                              Atonit_Act_Boxlink_Shipment_Id__c  
                                                                              FROM Atonit_Mktplace_Seller_Shipment_c 
                                                                              WHERE Atonit_Act_Boxlink_Shipment_Id__c IN :trackersSet];
                    
            list<Atonit_Mktplace_Seller_Orderc> listOrdertoUpdate = new list<Atonit_MktplaceSeller_Order_c>();
            map<string,string> mapSucessFind = new map<string,string> ();
            
            for(Atonit_Mktplace_Seller_Shipment_c stepToChanges : listOrdersByTrackers){ 
                if(mapParams.get(stepToChanges.Atonit_Act_Boxlink_Shipment_Id__c) != null || 
                   String.isBlank(String.valueOf(mapParams.get(stepToChanges.Atonit_Act_Boxlink_Shipment_Id__c) ))){
                       
                       String keyToMap2 = mapParams.get(stepToChanges.Atonit_Act_Boxlink_Shipment_Id__c
                       Atonit_Mktplace_Seller_Orderc orderToUpdt = new Atonit_MktplaceSeller_Orderc(Id = stepToChanges.Atonit_MktplaceSeller_Order_c,
                                                                                                           Atonit_Mktplace_Status_OMS_c = mapStatusMDT.get(keyToMap2),
                                                                                                          Atonit_Act_Boxlink_Status_Date__c = mapDate.get());
						
                       system.debug('orderToUpdt' + orderToUpdt);  //DEBUG

                       listOrdertoUpdate.add(orderToUpdt);
                       if(mapSucessFind.get(stepToChanges.Atonit_Act_Boxlink_Shipment_Id__c) == null){
                           system.debug('stepToChanges.Atonit_Act_Boxlink_Shipment_Id_c' + stepToChanges.Atonit_Act_Boxlink_Shipment_Id_c);  //DEBUG
                          mapSucessFind.put(stepToChanges.Atonit_Act_Boxlink_Shipment_Id__c, mapStatusMDT.get(keyToMap2));
                       }
                   }
            }
            
            system.debug('listOrdersByTrackers --->' + listOrdersByTrackers); //DEBUG
            system.debug('listOrdertoUpdate --->' + listOrdertoUpdate); //DEBUG

            for(string tracker :trackersSet){
                if(mapSucessFind.get(tracker) == null){
                     mapError.put(tracker, 'Reastrador ou Status Não Encontrado');
                }
            }
            
            // NOVO FOR
            
			
            list<Atonit_Mktplace_Seller_Orderc> listDatetoUpdate = new list<Atonit_MktplaceSeller_Order_c>();
            for(String dataEvento : mapDate.values()){
             
                Atonit_Mktplace_Seller_Orderc newOrder = new Atonit_MktplaceSeller_Orderc(Atonit_Act_Boxlink_Status_Date_c = dataEvento);
                listDatetoUpdate.add(newOrder);
                
               	System.debug('newOrder : ---> '+ newOrder);  //DEBUG
                System.debug('dataEvento : ---> '+ dataEvento);   //DEBUG
            } 
            
               	System.debug('listDatetoUpdate : ---> '+ listDatetoUpdate);  //DEBUG

                                            
			database.update(listOrdertoUpdate);
			database.update(listDatetoUpdate);
            
            if(!listOrdertoUpdate.isEmpty()){
                if(mapError.isEmpty()){
                    res.responseBody = Blob.valueOf('"Sucess":' + JSON.serialize(mapSucessFind));
                    res.statusCode = 200;
                    res.addHeader('Content-Type', 'application/json');
                }else{
                    res.responseBody = Blob.valueOf('"Sucess":' + JSON.serialize(mapSucessFind) + ', "Error":' +  JSON.serialize(mapError) );
                    res.statusCode = 206;
                    res.addHeader('Content-Type', 'application/json');
                }
            }else{
                res.responseBody = Blob.valueOf(' "Error":' +  JSON.serialize(mapError));
                res.statusCode = 404;
                res.addHeader('Content-Type', 'application/json');
            }
            
        }catch (Exception e){
            res.responseBody = Blob.valueOf(
                '{"mensagem":" Erro Interno, por favor procure Administrador",  "Error":500}');
            res.statusCode = 500;
            res.addHeader('Content-Type', 'application/json');
            
            system.debug('catch -->' + e);
        }
    }
    
    public class data { 
        String rastreadorTMS;
        String tipo;
        String dataEvento;
    }
}