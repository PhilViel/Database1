/****************************************************************************************************
Code de service		:		fntIQEE_EstimerCreditBaseARecevoir
Nom du service		:		EstimerCreditBaseARecevoir
But					:		Calculer l'estimation du crédit de base pour une convention donnée
Facette				:		IQÉÉ
Reférence			:		Guide du fiduciaire Revenu Québec sur l'IQEE et Rapport mensuel de l'estimation de l'IQEE à recevoir.

Parametres d'entrée :	Parametres									Description
                        ----------									----------------
                        iID_Convention								ID de la convention concernée par l'appel
                        @mTotal_Cotisations_Subventionnables		
                        dtDate_Fin									Date de fin de la période considérée par l'appel

Article du guide du fiduciaire 
5.2.1 Calcul du montant de base

Pour une année d’imposition donnée, à l’égard d’un bénéficiaire qui réside au Québec à la fin de cette année, le
montant de base est égal au moins élevé des montants suivants :

a) 10 % de l’ensemble des cotisations admissibles à l’égard du bénéficiaire pour l’année;
b) 500 $;


Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iID_Convention					Numéro identifiant de la convention
						S/O							iID_Beneficiaire				Numéro identifiant du bénéficiaire
						S/O							dtDate_Fin 						Date de fin concernée
						S/O							mMontantCreditBase				Montant du crédit de base estimée par les calculs.
						S/O							mTotal_Cotisations_Maximum2500  Montant maximum de subvention pouvant être versé pour l'année.



Exemple d'appel:
                SELECT * FROM DBO.[fntIQEE_EstimerCreditBaseARecevoir] (1234, 480.55,'2011-12-19')

Paramètres de sortie : Le crédit de base (CBQ) de l'IQEE estimé

Historique des modifications :
			
    Date        Programmeur                 Description
    ----------  ------------------------    -------------------------------------------
    2014-02-07  Stéphane Barbeau            Création de la fonction
    2016-09-06  Steeve Picard               Transformation en Inline Function
****************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_EstimerCreditBaseARecevoir (
    @iID_Convention INT, 
    @iID_Beneficiaire INT, 
    @mTotal_Cotisations_Subventionnables MONEY, 
    @dtDate_Fin DATETIME
)
RETURNS TABLE AS
RETURN (
    SELECT 
        iID_Convention = @iID_Convention, 
        iID_Beneficiaire = @iID_Beneficiaire, 
        dtDate_Fin = @dtDate_Fin, 
        mMontantCreditBase = X.Total_Subventionnables * 0.10, 
        mTotal_Cotisations_Maximum2500 = X.Total_Subventionnables
    FROM (
        SELECT
            CASE WHEN @mTotal_Cotisations_Subventionnables >= 2500 THEN 2500 ELSE @mTotal_Cotisations_Subventionnables END as Total_Subventionnables
        ) X
)				
