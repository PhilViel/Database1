CREATE PROCEDURE dbo.psTEMP_SPGkomenda
	(
	 @ConventionNO	varchar(25)
	)
AS
	BEGIN

SELECT 
            C.ConventionID,
            C.ConventionNo,
            C.dtRegStartDate,
            C.dtSignature,
            U.SignatureDate,
            PU.Min_UnitID,
            U.UnitID,
            U.InForceDate,
            C.dtEntreeEnVigueur,
            HBO.BirthDate,
            FCB.FCBOperDate
FROM dbo.Un_Convention C
JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
CROSS APPLY dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, C.ConventionID, NULL, NULL, NULL, NULL, 'INI', NULL, NULL, NULL, NULL, NULL) AS CB
JOIN dbo.Mo_Human HBO ON HBO.HumanID = CB.iID_Nouveau_Beneficiaire
LEFT JOIN ( -- Premier groupe d'unités
                        SELECT 
                                   U.ConventionID,
                                   Min_UnitID = MIN(U.UnitID)
                        FROM dbo.Un_Unit U
                        WHERE U.SignatureDate IS NOT NULL
                        GROUP BY        
                                   U.ConventionID
                        ) PU ON PU.ConventionID = C.ConventionID AND Min_UnitID = U.UnitID
LEFT JOIN (
                        SELECT -- Va chercher la date du FCB s'il y en a un sur la convention
                                   U.ConventionID,
                                   FCBOperDate = CASE    -- 2010-03-29 : JFG : Sélection de la plus petite date entre OperDate et EffectDate
                                                                                              WHEN MIN(O.OperDate) > MIN(Ct.EffectDate)  THEN MIN(Ct.EffectDate)
                                                                                              ELSE MIN(O.OperDate)
                                                                                  END
                        FROM dbo.Un_Unit U 
                        JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
                        JOIN Un_Oper O ON O.OperID = Ct.OperID
                        WHERE O.OperTypeID = 'FCB'
                                   AND O.OperID NOT IN (
                                               SELECT OperID
                                               FROM Un_OperCancelation
                                               UNION
                                               SELECT OperSourceID
                                               FROM Un_OperCancelation)
                        GROUP BY U.ConventionID
                        ) FCB ON FCB.ConventionID = C.ConventionID
WHERE C.ConventionNo = @ConventionNO --'X-20140930001'

end


