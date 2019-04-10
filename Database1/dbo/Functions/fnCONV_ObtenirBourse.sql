
/****************************************************************************************************
Code de service		:		fnCONV_ObtenirBourse
Nom du service		:		Obtenir la bourse estimée  
But					:		Récupérer le montant de bourse estimé selon les bourses versées lors des 3 dernières années
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                              Obligatoir
                        ----------                  ----------------                         --------------                       
                        @iIdConvention	            Identifiant unique de la convention      Oui
						@fQteUnité                  Quantité d’unités                        Oui

Exemple d'appel:
                
                SELECT dbo.fnCONV_ObtenirBourse (230242, 1)3.368)

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        S/O                         @mBourse                                    Montant estimé de la bourse

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-12-04					Fatiha Araar							Création de la fonction           
						2010-07-15					Jean-François Gauthier					Modification pour tenir compte du paramètre
																							applicatif CONV_RDEP_DATE_BOURSE
																							Ajout de la date de fin du relevé
						2010-08-17					Jean-François Gauthier					Correction d'un bug sur le montant calculé
						2013-02-11					Pierre-Luc Simard						Utilisation des montants fixes de la table Un_Plan au lieu 
																							des 3 dernières bourses de la table Un_PlanValues
 ****************************************************************************************************/
CREATE FUNCTION dbo.fnCONV_ObtenirBourse 
(
	@iIdConvention	INT
    ,@mQteUnité		MONEY
)
RETURNS MONEY
AS
	BEGIN
	 
		DECLARE @mBourse MONEY
						
		SELECT 
			@mBourse = (ISNULL(P.mRelDepProjBourse1,0) + ISNULL(P.mRelDepProjBourse2,0) + ISNULL(P.mRelDepProjBourse3,0)) * @mQteUnité
		FROM dbo.Un_Convention C  
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		WHERE C.ConventionID = @iIdConvention
										
		RETURN @mBourse

	END


