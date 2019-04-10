/****************************************************************************************************
Code de service		:		fnCONV_ObtenirAdmissibliteGroupeUniteCommissionActif
Nom du service		:		
But					:		    Obtenir si oui ou non le groupe d'unite est admissible pour la commission sur l'actif 
Facette				:		    CONV
Reférence			:		
Parametres d'entrée :	Parametres				Description                              Obligatoire
                                ----------                    ----------------                         --------------                       
                                @dtDate					Date			
						        @iID_GroupeUnite	    ID du groupe unite						
						
Exemple d'appel:       SELECT [dbo].[fnCONV_ObtenirAdmissibliteGroupeUniteCommissionActif] ('1800-01-01',724330)
                
Parametres de sortie : Table	    Champs									Description
					   -----------------    --------------------------			--------------------------
                       S/O                    @bAdmissibleCommissionActif		Indicateur pour dire si le groupe d'unité est 
																								    admissible ou non à la commission sur l'actif
                    
Historique des modifications :
			
						Date					Programmeur								Description							Référence
						----------			-------------------------------------	----------------------------		---------------
						2016-05-18		Maxime Martel							Création de la fonction           
 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fnCONV_ObtenirAdmissibliteGroupeUniteCommissionActif]
(
	@dtDate	DATETIME = NULL,
	@iID_GroupeUnite INT = NULL
)
RETURNS BIT
AS
BEGIN
	DECLARE @bAdmissibleCommissionActif BIT
	
	IF(@iID_GroupeUnite IS NOT NULL)
	BEGIN
		DECLARE 
        @dtDateDebutMois DATETIME

		SET @dtDate = ISNULL(@dtDate, GETDATE())
		
        -- On valide les paramètres
		IF dbo.fnGENE_ObtenirParametre('CONV_AGE_MIN_BENEF_COMM_ACTIF', @dtDate, NULL, NULL, NULL, NULL, NULL) NOT IN ('-1', '-2') 
			AND dbo.fnGENE_ObtenirParametre('CONV_DATE_SIGNATURE_MIN_COMM_ACTIF', @dtDate, NULL, NULL, NULL, NULL, NULL) NOT IN ('-1', '-2')
		BEGIN 
			DECLARE
				@iAgeBenef INT = dbo.fnGENE_ObtenirParametre('CONV_AGE_MIN_BENEF_COMM_ACTIF', @dtDate, NULL, NULL, NULL, NULL, NULL),
				@dtSignature DATETIME = dbo.fnGENE_ObtenirParametre('CONV_DATE_SIGNATURE_MIN_COMM_ACTIF', @dtDate, NULL, NULL, NULL, NULL, NULL)

			SELECT TOP 1 
				@bAdmissibleCommissionActif = COUNT(*) 
			FROM dbo.fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif(@dtDate, @iID_GroupeUnite, @iAgeBenef, @dtSignature)
		END
		ELSE
		BEGIN
			SET @bAdmissibleCommissionActif = 0
		END
	END
	ELSE
	BEGIN
		SET @bAdmissibleCommissionActif = 0
	END
	RETURN @bAdmissibleCommissionActif
END
