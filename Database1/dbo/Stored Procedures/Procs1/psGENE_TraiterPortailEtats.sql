
/****************************************************************************************************
Code de service		:		psGENE_TraiterPortailEtats
Nom du service		:		Ce service permet de détruire les enregistrement de la table tblGENE_PortailAuthentification
But					:		Récupérer le type 
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@@iUserId					Identifiant de l’humain
Exemple d'appel:
                
                EXEC dbo.psGENE_TraiterPortailEtats 176465

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-09-06					Eric Michaud							Création du service
						2011-09-26					Donald Huppé							Modifier la valeur du @profile_name
						2011-11-03					Eric Michaud							Insertion d'une note au dossier
 ****************************************************************************************************/
CREATE PROCEDURE dbo.psGENE_TraiterPortailEtats
				(					
					@iUserId INT
				)
AS
	BEGIN

	SET NOCOUNT ON

	declare @mail varchar(500);
	declare @param1 varchar(200);
	declare @param2 varchar(200);
	declare @param3 varchar(200);
	declare @note varchar(200);
	declare @NouvelEtat	int;
	
	select @NouvelEtat = 7 
	
	IF EXISTS (SELECT 1 from tblGENE_PortailAuthentification where iUserId = @iUserId AND iEtat <> 0)
	begin
		select @mail = (select 'ID = ' + cast(iUserId as varchar(15)) + '  Code Statut = ' +  cast(iIDEtat AS varchar(1))+ '  Description = ' + vcDescEtat
		from tblGENE_PortailAuthentification,tblGENE_PortailEtat 
		where iUserId = @iUserId AND iEtat = iIDEtat )
		
		SELECT @param1 = dbo.fnGENE_ObtenirParametre('GENE_PORTAILAUTHENTIFICATION_PROFILE_NAME',
																 NULL,NULL,NULL,NULL,NULL,NULL)
		SELECT @param2 = dbo.fnGENE_ObtenirParametre('GENE_PORTAILAUTHENTIFICATION_RECIPIENTS',
																 NULL,NULL,NULL,NULL,NULL,NULL)
		SELECT @param3 = dbo.fnGENE_ObtenirParametre('GENE_PORTAILAUTHENTIFICATION_SUBJECT',
																 NULL,NULL,NULL,NULL,NULL,NULL)
		
		EXEC msdb.dbo.sp_send_dbmail @profile_name = @param1, @recipients = @param2,  @body = @mail , @subject = @param3
	end
	ELSE
		-- Mettre l'état a Expiré (Inscription non-confirmée après 30 jours) 
		UPDATE tblGENE_PortailAuthentification
		SET iEtat = @NouvelEtat 
		WHERE iUserId = @iUserId

		-- Gestion d'erreur
		IF @@ERROR = 0
		BEGIN
			INSERT INTO CRQ_Log (
			ConnectID,
			LogTableName,
			LogCodeID,
			LogTime,
			LogActionID,
			LogDesc,
			LogText)				
			SELECT
				CASE WHEN S.SubscriberID IS NOT NULL THEN PS.vcValeur_Parametre ELSE PB.vcValeur_Parametre END,
				CASE WHEN S.SubscriberID IS NOT NULL THEN 'Un_Subscriber' ELSE 'Un_Beneficiary' END,
				@iUserId,
				GETDATE(),
				LA.LogActionID,
				LogDesc = CASE WHEN S.SubscriberID IS NOT NULL THEN 'Souscripteur : ' ELSE 'Bénéficiaire : ' END + H.LastName + ', ' + H.FirstName,
				LogText = 'tblGENE_PortailAuthentification changer iEtat = 7'
				FROM dbo.Mo_Human H
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
				LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
				LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
				JOIN tblGENE_TypesParametre TPS ON TPS.vcCode_Type_Parametre = 'GENE_AUTHENTIFICATION_SOUSC_CONNECTID' 
				JOIN tblGENE_Parametres PS ON TPS.iID_Type_Parametre = PS.iID_Type_Parametre
				JOIN tblGENE_TypesParametre TPB ON TPB.vcCode_Type_Parametre = 'GENE_AUTHENTIFICATION_BENEF_CONNECTID'
				JOIN tblGENE_Parametres PB ON TPB.iID_Type_Parametre = PB.iID_Type_Parametre
				WHERE H.HumanID = @iUserId

		END -- Gestion du log

	END


