
/****************************************************************************************************
Code de service		:		psGENE_RapportHistoriqueSACConvention
Nom du service		:		Rapport historique SAC pour une convention 
But					:		Rapport historique SAC pour une convention 
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@ConventionNo				ConventionNo
Exemple d'appel:
                
				EXEC psGENE_RapportHistoriqueSACConvention 373158

Parametres de sortie :	Champs						Description
						-----------------			---------------------------	
						OperID
						OperDate
						EffectDate
						OperTypeID
						CodeNSF	
						Total	
						Cotisation	
						Fee	
						Ecart	
						SubscInsur	
						BenefInsur	
						TaxOnInsur	
						Interests	
						mMontant_Frais	
						mMontant_TaxeTPS	
						mMontant_TaxeTVQ	
						LastReceiveDate	
						fCESG	
						fACESG	
						fCLB	
						iOperationID	
						HaveCheque	
						LockAccount	
						AnticipedCPA	
						OperTypeIDView	
						PlanTypeIDView	
						Status
                   
Historique des modifications :
			
	Date						Programmeur								Description							Référence
	----------					-------------------------------------	----------------------------		---------------
	2012-02-01					Eric Michaud							Création du service
 ****************************************************************************************************/

CREATE PROCEDURE dbo.psGENE_RapportHistoriqueSACConvention(
	@ConventionNo Varchar(15)) -- Id de l’objet (ConventionID).	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @ConventionID integer
	
	SELECT @ConventionID = ConventionID
	FROM dbo.Un_Convention 
	WHERE ConventionNo = @ConventionNo
	
	-- Appel de l'extraction
	exec SL_UN_TransactionHistoryForCS 'CNV',@ConventionID
		
END


