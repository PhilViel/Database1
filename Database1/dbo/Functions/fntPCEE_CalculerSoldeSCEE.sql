/****************************************************************************************************
Code de service		:		fntPCEE_CalculerSoldeSCEE
Nom du service		:		CalculerSoldeSCEE
But					:		Calculer le solde SCEE d'une convention
Facette				:		PCEE
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_Convention              ID de la convention concernée par l'appel
                        dtDate_Fin                  Date de fin de la période considérée par l'appel


Exemple d'appel:
                SELECT * FROM DBO.[fntPCEE_CalculerSoldeSCEE] (374011, NULL)

Parametres de sortie : Le solde SCEE

Historique des modifications :
			
		Date		Programmeur								Description							Référence
		----------	------------------------	----------------------------		---------------
		2016-04-06  Steeve Picard				Création de la fonction
 ****************************************************************************************************/
 CREATE FUNCTION [dbo].[fntPCEE_CalculerSoldeSCEE]
(	
	@iID_Convention		INT,
	@dtDate_Fin  		DATETIME = NULL,
	@bParOperTypeID		BIT = 0
)
RETURNS @Result TABLE (
	ConventionID INT NOT NULL,
	mSCEE_Base MONEY DEFAULT(0),
	mSCEE_Plus MONEY DEFAULT(0),
	mSCEE_BEC MONEY DEFAULT(0),
	mSCEE_Interet MONEY DEFAULT(0),
	OperTypeID varchar(5)
) AS
BEGIN
	DECLARE @vcListOper varchar(1000) = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_SCEE') + ','
									  + dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_SCEE+') + ','
									  + dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_CALCUL_RENDEMENT_BEC') + ','

	INSERT INTO @Result (ConventionID, mSCEE_Base, mSCEE_Plus, mSCEE_BEC, OperTypeID)
		SELECT C.ConventionID,
			   mSCEE_Base = IsNull(Sum(IsNull(C.fCESG,0 )), 0),
			   mSCEE_Plus = IsNull(Sum(IsNull(C.fACESG, 0)), 0),
			   mSCEE_BEC = IsNull(Sum(IsNull(C.fCLB, 0)), 0),
			   CASE @bParOperTypeID WHEN 0 THEN NULL ELSE O.OperTypeID END
		  FROM dbo.Un_CESP C
		       JOIN dbo.Un_Oper O ON O.OperID = C.OperID --AND O.OperDate <= IsNull(@dtDate_Fin, GETDATE())
			   LEFT JOIN (
				SELECT OC.OperSourceID, OC.OperID
					FROM dbo.Un_OperCancelation OC
					    JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
					WHERE Cast(O.OperDate as DATE) < IsNull(@dtDate_Fin, GETDATE())
			   ) OC ON OC.OperSourceID = O.OperID
		 WHERE C.ConventionID = @iID_Convention
		   AND Cast(O.OperDate as DATE) <= IsNull(@dtDate_Fin, GETDATE())
		   AND OC.OperID IS NULL
		 GROUP BY C.ConventionID, CASE @bParOperTypeID WHEN 0 THEN NULL ELSE O.OperTypeID END

	MERGE @Result as target
	USING (SELECT CO.ConventionID, CASE @bParOperTypeID WHEN 0 THEN NULL ELSE O.OperTypeID END as OperTypeID, IsNull(Sum(CO.ConventionOperAmount), 0)
		     FROM dbo.Un_ConventionOper CO
		          JOIN (
					 SELECT strField
					  FROM dbo.fntGENE_SplitIntoTable(@vcListOper, ',')
					 WHERE Rtrim(LTrim(strField)) <> ''
				  ) T ON T.strField = CO.ConventionOperTypeID
				  JOIN dbo.Un_Oper O ON O.OperID = CO.OperID 
				  LEFT JOIN (
					SELECT OC.OperSourceID, OC.OperID
					  FROM dbo.Un_OperCancelation OC
					       JOIN dbo.Un_Oper O ON O.OperID = OC.OperID
					 WHERE Cast(O.OperDate as DATE) <= IsNull(@dtDate_Fin, GETDATE())
				  ) OC ON OC.OperSourceID = O.OperID
			WHERE CO.ConventionID = @iID_Convention
			  AND Cast(O.OperDate as DATE) <= IsNull(@dtDate_Fin, GETDATE())
			  AND OC.OperID IS NULL
			GROUP BY CO.ConventionID, CASE @bParOperTypeID WHEN 0 THEN NULL ELSE O.OperTypeID END
		  ) AS Source (ConventionID, OperTypeID, Interet) 
		ON (target.ConventionID = source.ConventionID And target.OperTypeID = source.OperTypeID)
		WHEN MATCHED THEN
			UPDATE SET mSCEE_Interet = Interet
		WHEN NOT MATCHED THEN
			INSERT (ConventionID, OperTypeID, mSCEE_Interet)
			VALUES (source.ConventionID, source.OperTypeID, source.Interet);

	RETURN
END
